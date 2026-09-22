using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

using ScaleFlow.DTOs;
using ScaleFlow.Models;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ProfileController : ControllerBase
{
    private readonly UserManager<User> _userManager;

    public ProfileController(UserManager<User> userManager)
    {
        _userManager = userManager;
    }

    // ============================================================
    // GET CURRENT USER PROFILE
    // GET /api/Profile/me
    // ============================================================

    [HttpGet("me")]
    public async Task<IActionResult> GetMyProfile(
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();

        if (userId is null)
        {
            return Unauthorized(
                ApiResponse<object>.Fail(
                    "Unable to identify the authenticated user."));
        }

        var user = await _userManager.Users
            .Include(x => x.Organization)
            .FirstOrDefaultAsync(
                x =>
                    x.Id == userId.Value &&
                    !x.IsDeleted &&
                    x.IsActive,
                cancellationToken);

        if (user is null)
        {
            return NotFound(
                ApiResponse<object>.Fail(
                    "User profile was not found."));
        }

        var roles = await _userManager.GetRolesAsync(user);

        var profile = MapToResponse(user, roles);

        return Ok(
            ApiResponse<ProfileResponse>.Ok(
                profile));
    }

    // ============================================================
    // UPDATE CURRENT USER PROFILE
    // PUT /api/Profile/me
    // ============================================================

    [HttpPut("me")]
    public async Task<IActionResult> UpdateMyProfile(
        [FromBody] UpdateProfileRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();

        if (userId is null)
        {
            return Unauthorized(
                ApiResponse<object>.Fail(
                    "Unable to identify the authenticated user."));
        }

        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            return BadRequest(
                ApiResponse<object>.Fail(
                    "Full name is required."));
        }

        var user = await _userManager.Users
            .FirstOrDefaultAsync(
                x =>
                    x.Id == userId.Value &&
                    !x.IsDeleted &&
                    x.IsActive,
                cancellationToken);

        if (user is null)
        {
            return NotFound(
                ApiResponse<object>.Fail(
                    "User profile was not found."));
        }

        user.FullName = request.FullName.Trim();

        user.JobTitle = Clean(request.JobTitle);

        user.Company = Clean(request.Company);

        user.Department = Clean(request.Department);

        user.Phone = Clean(request.Phone);

        user.PhoneNumber = Clean(request.Phone);

        user.Country = Clean(request.Country);

        user.City = Clean(request.City);

        user.ShortBio = Clean(request.ShortBio);

        user.Language = Clean(request.Language);

        user.DefaultView = string.IsNullOrWhiteSpace(
                request.DefaultView)
            ? "Projects"
            : request.DefaultView.Trim();

        user.NotificationsEnabled =
            request.NotificationsEnabled;

        user.UpdatedAt = DateTimeOffset.UtcNow;

        var result = await _userManager.UpdateAsync(user);

        if (!result.Succeeded)
        {
            return BadRequest(
                ApiResponse<object>.Fail(
                    string.Join(
                        "; ",
                        result.Errors.Select(
                            error => error.Description))));
        }

        var roles = await _userManager.GetRolesAsync(user);

        var profile = MapToResponse(user, roles);

        return Ok(
            ApiResponse<ProfileResponse>.Ok(
                profile,
                "Profile updated successfully."));
    }

    // ============================================================
    // CURRENT USER ID FROM JWT
    // ============================================================

    private int? GetCurrentUserId()
    {
        var value = User.FindFirstValue(
            ClaimTypes.NameIdentifier);

        if (int.TryParse(value, out var userId))
        {
            return userId;
        }

        return null;
    }

    // ============================================================
    // RESPONSE MAPPER
    // ============================================================

    private static ProfileResponse MapToResponse(
        User user,
        IList<string> roles)
    {
        return new ProfileResponse
        {
            UserId = user.Id,

            Email = user.Email ?? string.Empty,

            FullName = user.FullName,

            JobTitle = user.JobTitle,

            Role = roles.FirstOrDefault(),

            Company = user.Company,

            Department = user.Department,

            Phone = user.Phone,

            Country = user.Country,

            City = user.City,

            ShortBio = user.ShortBio,

            Language = user.Language,

            DefaultView = string.IsNullOrWhiteSpace(
                    user.DefaultView)
                ? "Projects"
                : user.DefaultView,

            NotificationsEnabled =
                user.NotificationsEnabled,

            AvatarUrl = user.AvatarUrl
        };
    }

    private static string? Clean(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return value.Trim();
    }
}
