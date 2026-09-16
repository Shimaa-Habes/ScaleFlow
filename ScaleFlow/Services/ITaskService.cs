using System.Security.Claims;
using ScaleFlow.DTOs;

namespace ScaleFlow.Services;

public interface ITaskService
{
    Task<IReadOnlyList<TaskResponse>> ListTasks(ClaimsPrincipal user, int projectId, int page, int pageSize, CancellationToken cancellationToken);
    Task<TaskResponse> GetTask(ClaimsPrincipal user, int projectId, int id, CancellationToken cancellationToken);
    Task<TaskResponse> CreateTask(ClaimsPrincipal user, int projectId, TaskRequest request, CancellationToken cancellationToken);
    Task<TaskResponse> UpdateTask(ClaimsPrincipal user, int projectId, int id, TaskRequest request, CancellationToken cancellationToken);
    Task DeleteTask(ClaimsPrincipal user, int projectId, int id, CancellationToken cancellationToken);
}
