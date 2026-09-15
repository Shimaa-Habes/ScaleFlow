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

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var result = await _authService.RegisterAsync(request, cancellationToken);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var result = await _authService.LoginAsync(request, cancellationToken);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
    }

    [Authorize]
    [HttpGet("me")]
    public IActionResult Me()
    {
        return Ok(new
        {
            userId = User.FindFirstValue(ClaimTypes.NameIdentifier),
            email = User.FindFirstValue(ClaimTypes.Email),
            user = User.Identity?.Name,
            roles = User.FindAll(ClaimTypes.Role).Select(claim => claim.Value).ToArray()
        });
    }

    [Authorize]
    [HttpGet("test")]
    public IActionResult Test()
    {
        return Me();
    }

    [Authorize(Roles = RoleConstants.ProjectManager)]
    [HttpGet("project-manager-only")]
    public IActionResult ProjectManagerOnly()
    {
        return Ok(new { message = "Project manager access granted." });
    }

    [Authorize(Roles = RoleConstants.TeamLeader)]
    [HttpGet("team-leader-only")]
    public IActionResult TeamLeaderOnly()
    {
        return Ok(new { message = "Team leader access granted." });
    }

    [Authorize(Roles = RoleConstants.TeamMember)]
    [HttpGet("team-member-only")]
    public IActionResult TeamMemberOnly()
    {
        return Ok(new { message = "Team member access granted." });
    }

    [Authorize(Roles = RoleConstants.Client)]
    [HttpGet("client-only")]
    public IActionResult ClientOnly()
    {
        return Ok(new { message = "Client access granted." });
    }
}
