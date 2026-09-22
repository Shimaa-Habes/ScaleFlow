using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using ScaleFlow.Constants;
using ScaleFlow.DTOs;
using ScaleFlow.Services;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    // =========================
    // REGISTER
    // =========================
    [HttpPost("register")]
    public async Task<IActionResult> Register(
        [FromBody] RegisterRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await _authService.RegisterAsync(
                request,
                cancellationToken);

            return Ok(
                ApiResponse<AuthResponse>.Ok(result));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(
                ApiResponse<object>.Fail(ex.Message));
        }
    }

    // =========================
    // LOGIN
    // =========================
    [HttpPost("login")]
    public async Task<IActionResult> Login(
        [FromBody] LoginRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await _authService.LoginAsync(
                request,
                cancellationToken);

            return Ok(
                ApiResponse<AuthResponse>.Ok(result));
        }
        catch (InvalidOperationException ex)
        {
            return Unauthorized(
                ApiResponse<object>.Fail(ex.Message));
        }
    }

    // =========================
    // CURRENT USER
    // =========================
    [Authorize]
    [HttpGet("me")]
    public IActionResult Me()
    {
        return Ok(new
        {
            userId = User.FindFirstValue(
                ClaimTypes.NameIdentifier),

            email = User.FindFirstValue(
                ClaimTypes.Email),

            user = User.Identity?.Name,

            roles = User
                .FindAll(ClaimTypes.Role)
                .Select(claim => claim.Value)
                .ToArray()
        });
    }

    // =========================
    // AUTH TEST
    // =========================
    [Authorize]
    [HttpGet("test")]
    public IActionResult Test()
    {
        return Me();
    }

    // =========================
    // PROJECT MANAGER
    // =========================
    [Authorize(Roles = RoleConstants.ProjectManager)]
    [HttpGet("project-manager-only")]
    public IActionResult ProjectManagerOnly()
    {
        return Ok(
            ApiResponse<object>.Ok(
                null,
                "Project manager access granted."));
    }

    // =========================
    // TEAM LEADER
    // =========================
    [Authorize(Roles = RoleConstants.TeamLeader)]
    [HttpGet("team-leader-only")]
    public IActionResult TeamLeaderOnly()
    {
        return Ok(
            ApiResponse<object>.Ok(
                null,
                "Team leader access granted."));
    }

    // =========================
    // TEAM MEMBER
    // =========================
    [Authorize(Roles = RoleConstants.TeamMember)]
    [HttpGet("team-member-only")]
    public IActionResult TeamMemberOnly()
    {
        return Ok(
            ApiResponse<object>.Ok(
                null,
                "Team member access granted."));
    }

    // =========================
    // CLIENT
    // =========================
    [Authorize(Roles = RoleConstants.Client)]
    [HttpGet("client-only")]
    public IActionResult ClientOnly()
    {
        return Ok(
            ApiResponse<object>.Ok(
                null,
                "Client access granted."));
    }
}