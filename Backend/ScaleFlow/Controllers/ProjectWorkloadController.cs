using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ScaleFlow.DTOs;
using ScaleFlow.Services;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/projects/{projectId}/workload")]
[Authorize]
public class ProjectWorkloadController : ControllerBase
{
    private readonly IWorkloadService _workloadService;

    public ProjectWorkloadController(IWorkloadService workloadService)
    {
        _workloadService = workloadService;
    }

    [HttpGet]
    public async Task<IActionResult> GetProjectWorkload(int projectId, CancellationToken cancellationToken)
    {
        var workload = await _workloadService.GetProjectWorkload(User, projectId, cancellationToken);
        return Ok(ApiResponse<ProjectWorkloadSummaryResponse>.Ok(workload));
    }

    [HttpGet("members/{userId}")]
    public async Task<IActionResult> GetMemberWorkload(int projectId, int userId, CancellationToken cancellationToken)
    {
        var memberWorkload = await _workloadService.GetMemberWorkload(User, projectId, userId, cancellationToken);
        return Ok(ApiResponse<MemberWorkloadResponse>.Ok(memberWorkload));
    }

    [HttpGet("tasks/{taskId}/assignments")]
    public async Task<IActionResult> ListTaskAssignments(int projectId, int taskId, CancellationToken cancellationToken)
    {
        var assignments = await _workloadService.ListTaskAssignments(User, projectId, taskId, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<TaskAssignmentResponse>>.Ok(assignments));
    }

    [HttpPost("tasks/{taskId}/assignments")]
    public async Task<IActionResult> AssignTask(
        int projectId, int taskId, [FromBody] AssignTaskRequest request, CancellationToken cancellationToken)
    {
        var assignment = await _workloadService.AssignTask(User, projectId, taskId, request, cancellationToken);
        return Ok(ApiResponse<TaskAssignmentResponse>.Ok(assignment, "Task assigned successfully."));
    }

    [HttpDelete("tasks/{taskId}/assignments/{userId}")]
    public async Task<IActionResult> RemoveAssignment(
        int projectId, int taskId, int userId, CancellationToken cancellationToken)
    {
        await _workloadService.RemoveTaskAssignment(User, projectId, taskId, userId, cancellationToken);
        return Ok(ApiResponse<object>.Ok(null, "Task assignment removed."));
    }
}
