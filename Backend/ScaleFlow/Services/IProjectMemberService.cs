using System.Security.Claims;
using ScaleFlow.DTOs;

namespace ScaleFlow.Services;

public interface IProjectMemberService
{
    Task<IReadOnlyList<ProjectMemberResponse>> ListMembers(ClaimsPrincipal user, int projectId, int page, int pageSize, CancellationToken cancellationToken);
    Task<ProjectMemberResponse> GetMember(ClaimsPrincipal user, int projectId, int userId, CancellationToken cancellationToken);
    Task<ProjectMemberResponse> AddMember(ClaimsPrincipal user, int projectId, AddProjectMemberRequest request, CancellationToken cancellationToken);
    Task<ProjectMemberResponse> UpdateMember(ClaimsPrincipal user, int projectId, int userId, UpdateProjectMemberRequest request, CancellationToken cancellationToken);
    Task RemoveMember(ClaimsPrincipal user, int projectId, int userId, CancellationToken cancellationToken);
}
