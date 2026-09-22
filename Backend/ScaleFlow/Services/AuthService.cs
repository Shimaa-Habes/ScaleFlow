using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using ScaleFlow.Constants;
using ScaleFlow.DTOs;
using ScaleFlow.Models;
using ScaleFlow.Options;

namespace ScaleFlow.Services;

public class AuthService : IAuthService
{
    private readonly UserManager<User> _userManager;
    private readonly RoleManager<Role> _roleManager;
    private readonly SignInManager<User> _signInManager;
    private readonly ScaleFlowDbContext _dbContext;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly JwtSettings _jwtSettings;

    public AuthService(
        UserManager<User> userManager,
        RoleManager<Role> roleManager,
        SignInManager<User> signInManager,
        ScaleFlowDbContext dbContext,
        IJwtTokenService jwtTokenService,
        IOptions<JwtSettings>? jwtSettings = null)
    {
        _userManager = userManager;
        _roleManager = roleManager;
        _signInManager = signInManager;
        _dbContext = dbContext;
        _jwtTokenService = jwtTokenService;
        _jwtSettings = jwtSettings?.Value ?? new JwtSettings();
    }

    public async Task<AuthResponse> RegisterAsync(
        RegisterRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            throw new InvalidOperationException("Full name is required.");
        }

        if (string.IsNullOrWhiteSpace(request.Email))
        {
            throw new InvalidOperationException("Email is required.");
        }

        if (string.IsNullOrWhiteSpace(request.Password))
        {
            throw new InvalidOperationException("Password is required.");
        }

        if (request.OrganizationId <= 0)
        {
            throw new InvalidOperationException("OrganizationId is required.");
        }

        var email = request.Email.Trim();

        var normalizedEmail = _userManager.NormalizeEmail(email);

        var existingUser = await _userManager.FindByEmailAsync(email);

        if (existingUser is not null)
        {
            throw new InvalidOperationException(
                "A user with this email already exists.");
        }

        var organizationExists = await _dbContext.Organizations
            .AnyAsync(
                o => o.Id == request.OrganizationId && !o.IsDeleted,
                cancellationToken);

        if (!organizationExists)
        {
            throw new InvalidOperationException(
                "Organization not found.");
        }

        var user = new User
        {
            FullName = request.FullName.Trim(),

            Email = email,
            NormalizedEmail = normalizedEmail,

            UserName = email,
            NormalizedUserName = _userManager.NormalizeName(email),

            PhoneNumber = request.Phone,
            Phone = request.Phone,

            OrganizationId = request.OrganizationId,
            IsActive = true,
            IsDeleted = false,
            EmailConfirmed = false,
            CreatedAt = DateTimeOffset.UtcNow
        };

        var result = await _userManager.CreateAsync(
            user,
            request.Password);

        if (!result.Succeeded)
        {
            throw new InvalidOperationException(
                string.Join(
                    "; ",
                    result.Errors.Select(e => e.Description)));
        }

        var defaultRole = RoleConstants.Client;

        await EnsureRoleExistsAsync(defaultRole);

        var roleResult = await _userManager.AddToRoleAsync(
            user,
            defaultRole);

        if (!roleResult.Succeeded)
        {
            throw new InvalidOperationException(
                string.Join(
                    "; ",
                    roleResult.Errors.Select(e => e.Description)));
        }

        var roles = await _userManager.GetRolesAsync(user);

        var token = _jwtTokenService.GenerateToken(
            user,
            roles);

        return new AuthResponse
        {
            UserId = user.Id,
            Email = user.Email ?? string.Empty,
            FullName = user.FullName,
            AccessToken = token,
            ExpiresAt = DateTimeOffset.UtcNow.AddMinutes(
                _jwtSettings.ExpiryMinutes),
            Roles = roles.ToList()
        };
    }

   public async Task<AuthResponse> LoginAsync(
    LoginRequest request,
    CancellationToken cancellationToken = default)
{
    if (string.IsNullOrWhiteSpace(request.Email) ||
        string.IsNullOrWhiteSpace(request.Password))
    {
        throw new InvalidOperationException(
            "Email and password are required.");
    }

    var email = request.Email.Trim();

    // Find user directly by Email.
    var user = await _userManager.Users
        .FirstOrDefaultAsync(
            u => u.Email == email,
            cancellationToken);

    if (user is null)
    {
        throw new InvalidOperationException(
            "Invalid email or password.");
    }

    if (!user.IsActive || user.IsDeleted)
    {
        throw new InvalidOperationException(
            "User account is not active.");
    }

    // Verify password using ASP.NET Identity.
    var passwordValid = await _userManager.CheckPasswordAsync(
        user,
        request.Password);

    if (!passwordValid)
    {
        throw new InvalidOperationException(
            "Invalid email or password.");
    }

    user.LastLoginAt = DateTimeOffset.UtcNow;

    var updateResult = await _userManager.UpdateAsync(user);

    if (!updateResult.Succeeded)
    {
        throw new InvalidOperationException(
            "Unable to update user login information.");
    }

    var roles = await _userManager.GetRolesAsync(user);

    var token = _jwtTokenService.GenerateToken(
        user,
        roles);

    return new AuthResponse
    {
        UserId = user.Id,
        Email = user.Email ?? string.Empty,
        FullName = user.FullName,
        AccessToken = token,
        ExpiresAt = DateTimeOffset.UtcNow.AddMinutes(
            _jwtSettings.ExpiryMinutes),
        Roles = roles.ToList()
    };
}

    public async Task<User?> FindUserByEmailAsync(
        string email,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            return null;
        }

        return await _userManager.FindByEmailAsync(
            email.Trim());
    }

    private async Task EnsureRoleExistsAsync(string roleName)
    {
        if (!await _roleManager.RoleExistsAsync(roleName))
        {
            await _roleManager.CreateAsync(
                new Role
                {
                    Name = roleName,
                    Code = roleName,
                    Scope = RoleScope.Global,
                    IsSystem = true
                });
        }
    }
}