using System.Security.Claims;
using ScaleFlow.DTOs;

namespace ScaleFlow.Services;

public interface IProjectProgressService
{
    Task<ProjectProgressResponse> GetProgress(ClaimsPrincipal user, int projectId, CancellationToken cancellationToken);
}
