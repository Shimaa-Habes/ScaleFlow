using System.Security.Claims;
using ScaleFlow.DTOs;

namespace ScaleFlow.Services;

public interface IProjectService
{
    Task<IReadOnlyList<ProjectResponse>> ListProjects(ClaimsPrincipal user, int page, int pageSize, CancellationToken cancellationToken);
    Task<ProjectResponse> GetProject(ClaimsPrincipal user, int id, CancellationToken cancellationToken);
    Task<ProjectResponse> CreateProject(ClaimsPrincipal user, ProjectRequest request, CancellationToken cancellationToken);
    Task<ProjectResponse> UpdateProject(ClaimsPrincipal user, int id, ProjectRequest request, CancellationToken cancellationToken);
    Task DeleteProject(ClaimsPrincipal user, int id, CancellationToken cancellationToken);
}
