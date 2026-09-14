using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using ScaleFlow.Constants;
using ScaleFlow.DTOs;
using ScaleFlow.Models;
using ScaleFlow.Options;
using ScaleFlow.Services;
using Xunit;
using OptionsFactory = Microsoft.Extensions.Options.Options;

namespace ScaleFlow.Tests;

public class AuthServiceTests
{
    private static ServiceProvider CreateServiceProvider()
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddDbContext<ScaleFlowDbContext>(options =>
            options.UseInMemoryDatabase(Guid.NewGuid().ToString()));

        services.AddIdentity<User, Role>(options =>
            {
                options.Password.RequireDigit = true;
                options.Password.RequireLowercase = true;
                options.Password.RequireUppercase = true;
                options.Password.RequireNonAlphanumeric = true;
                options.Password.RequiredLength = 8;
                options.User.RequireUniqueEmail = true;
            })
            .AddEntityFrameworkStores<ScaleFlowDbContext>()
            .AddDefaultTokenProviders();

        return services.BuildServiceProvider();
    }

    private static IJwtTokenService CreateJwtTokenService()
    {
        return new JwtTokenService(OptionsFactory.Create(new JwtSettings
        {
            Issuer = "ScaleFlow",
            Audience = "ScaleFlow-Api",
            SecretKey = "ThisIsADevelopmentJwtSecretKey123!",
            ExpiryMinutes = 60
        }));
    }

    [Fact]
    public async Task RegisterAsync_ShouldCreateClientUser()
    {
        using var provider = CreateServiceProvider();
        var db = provider.GetRequiredService<ScaleFlowDbContext>();
        var organization = new Organization
        {
            Name = "Test Org",
            Slug = "test-org",
            Code = "TEST",
            CreatedAt = DateTimeOffset.UtcNow
        };
        db.Organizations.Add(organization);
        await db.SaveChangesAsync();

        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        var signInManager = provider.GetRequiredService<SignInManager<User>>();
        var authService = new AuthService(userManager, roleManager, signInManager, db, CreateJwtTokenService());

        var request = new RegisterRequest
        {
            FullName = "Alice Admin",
            Email = "alice@example.com",
            Password = "Password123!",
            Phone = "1234567890",
            OrganizationId = organization.Id
        };

        var result = await authService.RegisterAsync(request);

        Assert.Equal("alice@example.com", result.Email);
        Assert.Contains(RoleConstants.Client, result.Roles);
    }

    [Fact]
    public async Task RegisterAsync_ShouldRejectDuplicateEmail()
    {
        using var provider = CreateServiceProvider();
        var db = provider.GetRequiredService<ScaleFlowDbContext>();
        var organization = new Organization
        {
            Name = "Test Org",
            Slug = "test-org",
            Code = "TEST",
            CreatedAt = DateTimeOffset.UtcNow
        };
        db.Organizations.Add(organization);
        await db.SaveChangesAsync();

        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        var signInManager = provider.GetRequiredService<SignInManager<User>>();
        var authService = new AuthService(userManager, roleManager, signInManager, db, CreateJwtTokenService());

        var request = new RegisterRequest
        {
            FullName = "Alice Admin",
            Email = "alice@example.com",
            Password = "Password123!",
            OrganizationId = organization.Id
        };

        await authService.RegisterAsync(request);

        await Assert.ThrowsAsync<InvalidOperationException>(() => authService.RegisterAsync(request));
    }

    [Fact]
    public async Task LoginAsync_ShouldRejectInvalidPassword()
    {
        using var provider = CreateServiceProvider();
        var db = provider.GetRequiredService<ScaleFlowDbContext>();
        var organization = new Organization
        {
            Name = "Test Org",
            Slug = "test-org",
            Code = "TEST",
            CreatedAt = DateTimeOffset.UtcNow
        };
        db.Organizations.Add(organization);
        await db.SaveChangesAsync();

        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        var signInManager = provider.GetRequiredService<SignInManager<User>>();
        var authService = new AuthService(userManager, roleManager, signInManager, db, CreateJwtTokenService());

        var registerRequest = new RegisterRequest
        {
            FullName = "Alice Admin",
            Email = "alice@example.com",
            Password = "Password123!",
            OrganizationId = organization.Id
        };

        await authService.RegisterAsync(registerRequest);

        var loginRequest = new LoginRequest
        {
            Email = "alice@example.com",
            Password = "WrongPassword!"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(() => authService.LoginAsync(loginRequest));
    }
}
