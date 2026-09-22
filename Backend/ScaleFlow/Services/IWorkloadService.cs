using System.Security.Claims;
using ScaleFlow.DTOs;

namespace ScaleFlow.Services;

public interface IWorkloadService
{
    Task<ProjectWorkloadSummaryResponse> GetProjectWorkload(ClaimsPrincipal user, int projectId, CancellationToken ct);
    Task<MemberWorkloadResponse> GetMemberWorkload(ClaimsPrincipal user, int projectId, int userId, CancellationToken ct);
    Task<TaskAssignmentResponse> AssignTask(ClaimsPrincipal user, int projectId, int taskId, AssignTaskRequest request, CancellationToken ct);
    Task RemoveTaskAssignment(ClaimsPrincipal user, int projectId, int taskId, int assigneeUserId, CancellationToken ct);
    Task<IReadOnlyList<TaskAssignmentResponse>> ListTaskAssignments(ClaimsPrincipal user, int projectId, int taskId, CancellationToken ct);
}
