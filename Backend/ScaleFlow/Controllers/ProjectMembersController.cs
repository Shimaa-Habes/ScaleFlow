using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ScaleFlow.DTOs;
using ScaleFlow.Services;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/projects/{projectId}/members")]
[Authorize]
public class ProjectMembersController : ControllerBase
{
    private readonly IProjectMemberService _memberService;

    public ProjectMembersController(IProjectMemberService memberService)
    {
        _memberService = memberService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(int projectId, [FromQuery] QueryParameters queryParameters, CancellationToken cancellationToken)
    {
        var members = await _memberService.ListMembers(User, projectId, queryParameters.Page, queryParameters.PageSize, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<ProjectMemberResponse>>.Ok(members));
    }

    [HttpGet("{userId}")]
    public async Task<IActionResult> GetById(int projectId, int userId, CancellationToken cancellationToken)
    {
        var member = await _memberService.GetMember(User, projectId, userId, cancellationToken);
        return Ok(ApiResponse<ProjectMemberResponse>.Ok(member));
    }

    [HttpPost]
    public async Task<IActionResult> Add(int projectId, [FromBody] AddProjectMemberRequest request, CancellationToken cancellationToken)
    {
        var member = await _memberService.AddMember(User, projectId, request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { projectId, userId = member.UserId },
            ApiResponse<ProjectMemberResponse>.Ok(member, "Project member added."));
    }

    [HttpPut("{userId}")]
    public async Task<IActionResult> Update(int projectId, int userId, [FromBody] UpdateProjectMemberRequest request, CancellationToken cancellationToken)
    {
        var member = await _memberService.UpdateMember(User, projectId, userId, request, cancellationToken);
        return Ok(ApiResponse<ProjectMemberResponse>.Ok(member, "Project member updated."));
    }

    [HttpDelete("{userId}")]
    public async Task<IActionResult> Remove(int projectId, int userId, CancellationToken cancellationToken)
    {
        await _memberService.RemoveMember(User, projectId, userId, cancellationToken);
        return Ok(ApiResponse<object>.Ok(null, "Project member removed."));
    }
}
