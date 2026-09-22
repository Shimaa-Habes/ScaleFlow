using System.Security.Claims;
using ScaleFlow.DTOs;

namespace ScaleFlow.Services;

public interface ITeamService
{
    Task<IReadOnlyList<TeamResponse>> ListTeams(ClaimsPrincipal user, int projectId, int page, int pageSize, CancellationToken cancellationToken);
    Task<TeamResponse> GetTeam(ClaimsPrincipal user, int projectId, int id, CancellationToken cancellationToken);
    Task<TeamResponse> CreateTeam(ClaimsPrincipal user, int projectId, TeamRequest request, CancellationToken cancellationToken);
    Task<TeamResponse> UpdateTeam(ClaimsPrincipal user, int projectId, int id, TeamRequest request, CancellationToken cancellationToken);
    Task DeleteTeam(ClaimsPrincipal user, int projectId, int id, CancellationToken cancellationToken);
    Task<IReadOnlyList<TeamMemberResponse>> ListMembers(ClaimsPrincipal user, int projectId, int teamId, int page, int pageSize, CancellationToken cancellationToken);
    Task<TeamMemberResponse> GetMember(ClaimsPrincipal user, int projectId, int teamId, int userId, CancellationToken cancellationToken);
    Task<TeamMemberResponse> AddMember(ClaimsPrincipal user, int projectId, int teamId, AddTeamMemberRequest request, CancellationToken cancellationToken);
    Task<TeamMemberResponse> UpdateMember(ClaimsPrincipal user, int projectId, int teamId, int userId, UpdateTeamMemberRequest request, CancellationToken cancellationToken);
    Task RemoveMember(ClaimsPrincipal user, int projectId, int teamId, int userId, CancellationToken cancellationToken);
}
