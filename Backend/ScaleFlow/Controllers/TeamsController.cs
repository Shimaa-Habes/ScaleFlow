using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ScaleFlow.DTOs;
using ScaleFlow.Services;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/projects/{projectId}/teams")]
[Authorize]
public class TeamsController : ControllerBase
{
    private readonly ITeamService _teamService;

    public TeamsController(ITeamService teamService)
    {
        _teamService = teamService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(int projectId, [FromQuery] QueryParameters queryParameters, CancellationToken cancellationToken)
    {
        var teams = await _teamService.ListTeams(User, projectId, queryParameters.Page, queryParameters.PageSize, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<TeamResponse>>.Ok(teams));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int projectId, int id, CancellationToken cancellationToken)
    {
        var team = await _teamService.GetTeam(User, projectId, id, cancellationToken);
        return Ok(ApiResponse<TeamResponse>.Ok(team));
    }

    [HttpPost]
    public async Task<IActionResult> Create(int projectId, [FromBody] TeamRequest request, CancellationToken cancellationToken)
    {
        var team = await _teamService.CreateTeam(User, projectId, request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { projectId, id = team.Id },
            ApiResponse<TeamResponse>.Ok(team, "Team created."));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int projectId, int id, [FromBody] TeamRequest request, CancellationToken cancellationToken)
    {
        var team = await _teamService.UpdateTeam(User, projectId, id, request, cancellationToken);
        return Ok(ApiResponse<TeamResponse>.Ok(team, "Team updated."));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int projectId, int id, CancellationToken cancellationToken)
    {
        await _teamService.DeleteTeam(User, projectId, id, cancellationToken);
        return Ok(ApiResponse<object>.Ok(null, "Team deleted."));
    }

    [HttpGet("{teamId}/members")]
    public async Task<IActionResult> GetMembers(int projectId, int teamId, [FromQuery] QueryParameters queryParameters, CancellationToken cancellationToken)
    {
        var members = await _teamService.ListMembers(User, projectId, teamId, queryParameters.Page, queryParameters.PageSize, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<TeamMemberResponse>>.Ok(members));
    }

    [HttpGet("{teamId}/members/{userId}")]
    public async Task<IActionResult> GetMember(int projectId, int teamId, int userId, CancellationToken cancellationToken)
    {
        var member = await _teamService.GetMember(User, projectId, teamId, userId, cancellationToken);
        return Ok(ApiResponse<TeamMemberResponse>.Ok(member));
    }

    [HttpPost("{teamId}/members")]
    public async Task<IActionResult> AddMember(int projectId, int teamId, [FromBody] AddTeamMemberRequest request, CancellationToken cancellationToken)
    {
        var member = await _teamService.AddMember(User, projectId, teamId, request, cancellationToken);
        return CreatedAtAction(nameof(GetMember), new { projectId, teamId, userId = member.UserId },
            ApiResponse<TeamMemberResponse>.Ok(member, "Team member added."));
    }

    [HttpPut("{teamId}/members/{userId}")]
    public async Task<IActionResult> UpdateMember(int projectId, int teamId, int userId, [FromBody] UpdateTeamMemberRequest request, CancellationToken cancellationToken)
    {
        var member = await _teamService.UpdateMember(User, projectId, teamId, userId, request, cancellationToken);
        return Ok(ApiResponse<TeamMemberResponse>.Ok(member, "Team member updated."));
    }

    [HttpDelete("{teamId}/members/{userId}")]
    public async Task<IActionResult> RemoveMember(int projectId, int teamId, int userId, CancellationToken cancellationToken)
    {
        await _teamService.RemoveMember(User, projectId, teamId, userId, cancellationToken);
        return Ok(ApiResponse<object>.Ok(null, "Team member removed."));
    }
}
