using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using System.IdentityModel.Tokens.Jwt;
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

        var user = await userManager.FindByEmailAsync(request.Email);
        Assert.NotNull(user);
        Assert.NotEqual(request.Password, user!.PasswordHash);
        Assert.Equal(PasswordVerificationResult.Success,
            userManager.PasswordHasher.VerifyHashedPassword(user, user.PasswordHash!, request.Password));
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

    [Fact]
    public async Task LoginAsync_ShouldReturnTokenWithConfiguredClaims()
    {
        using var provider = CreateServiceProvider();
        var db = provider.GetRequiredService<ScaleFlowDbContext>();
        var organization = new Organization { Name = "Test Org", Slug = "test-org", Code = "TEST" };
        db.Organizations.Add(organization);
        await db.SaveChangesAsync();

        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        var signInManager = provider.GetRequiredService<SignInManager<User>>();
        var authService = new AuthService(userManager, roleManager, signInManager, db, CreateJwtTokenService());

        var result = await authService.RegisterAsync(new RegisterRequest
        {
            FullName = "Alice Admin",
            Email = "alice@example.com",
            Password = "Password123!",
            OrganizationId = organization.Id
        });

        var token = new JwtSecurityTokenHandler().ReadJwtToken(result.AccessToken);
        Assert.Equal("ScaleFlow", token.Issuer);
        Assert.Contains("ScaleFlow-Api", token.Audiences);
        Assert.Equal(result.UserId.ToString(), token.Claims.Single(c => c.Type == System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub).Value);
        Assert.Equal(result.Email, token.Claims.Single(c => c.Type == System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Email).Value);
        Assert.Contains(token.Claims, claim => claim.Type == System.Security.Claims.ClaimTypes.Role && claim.Value == RoleConstants.Client);
        Assert.True(token.ValidTo > DateTime.UtcNow);

        var login = await authService.LoginAsync(new LoginRequest
        {
            Email = result.Email,
            Password = "Password123!"
        });

        Assert.False(string.IsNullOrWhiteSpace(login.AccessToken));
    }

    [Fact]
    public async Task LoginAsync_ShouldRejectUnknownUser()
    {
        using var provider = CreateServiceProvider();
        var db = provider.GetRequiredService<ScaleFlowDbContext>();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        var signInManager = provider.GetRequiredService<SignInManager<User>>();
        var authService = new AuthService(userManager, roleManager, signInManager, db, CreateJwtTokenService());

        await Assert.ThrowsAsync<InvalidOperationException>(() => authService.LoginAsync(new LoginRequest
        {
            Email = "missing@example.com",
            Password = "Password123!"
        }));
    }

    [Fact]
    public void AuthController_ShouldDeclareAuthenticationAndRolePolicies()
    {
        var controllerType = typeof(ScaleFlow.Controllers.AuthController);
        var testMethod = controllerType.GetMethod(nameof(ScaleFlow.Controllers.AuthController.Test));

        Assert.NotNull(testMethod?.GetCustomAttributes(typeof(Microsoft.AspNetCore.Authorization.AuthorizeAttribute), true).SingleOrDefault());

        var protectedEndpoints = new Dictionary<string, string>
        {
            [nameof(ScaleFlow.Controllers.AuthController.ProjectManagerOnly)] = RoleConstants.ProjectManager,
            [nameof(ScaleFlow.Controllers.AuthController.TeamLeaderOnly)] = RoleConstants.TeamLeader,
            [nameof(ScaleFlow.Controllers.AuthController.TeamMemberOnly)] = RoleConstants.TeamMember,
            [nameof(ScaleFlow.Controllers.AuthController.ClientOnly)] = RoleConstants.Client
        };

        foreach (var endpoint in protectedEndpoints)
        {
            var method = controllerType.GetMethod(endpoint.Key);
            var roleAttribute = method?.GetCustomAttributes(typeof(Microsoft.AspNetCore.Authorization.AuthorizeAttribute), true)
                .Cast<Microsoft.AspNetCore.Authorization.AuthorizeAttribute>()
                .Single(attribute => attribute.Roles is not null);
            Assert.Equal(endpoint.Value, roleAttribute!.Roles);
        }
    }

    [Fact]
    public void JwtTokenService_ShouldEmitEachSupportedRoleClaim()
    {
        var user = new User { Id = 42, Email = "role@example.com", FullName = "Role User" };
        var tokenService = CreateJwtTokenService();

        foreach (var role in RoleConstants.All)
        {
            var token = new JwtSecurityTokenHandler().ReadJwtToken(tokenService.GenerateToken(user, new[] { role }));
            Assert.Contains(token.Claims, claim =>
                claim.Type == System.Security.Claims.ClaimTypes.Role && claim.Value == role);
        }
    }
}
