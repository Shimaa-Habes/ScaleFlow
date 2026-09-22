using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.DTOs;
using ScaleFlow.Middleware;
using ScaleFlow.Models;

namespace ScaleFlow.Services;

public class TeamService : ITeamService
{
    private readonly ScaleFlowDbContext _context;
    private readonly IProjectService _projectService;

    public TeamService(ScaleFlowDbContext context, IProjectService projectService)
    {
        _context = context;
        _projectService = projectService;
    }

    private async Task<ProjectResponse> RequireOwner(ClaimsPrincipal user, int projectId, CancellationToken ct)
    {
        var project = await _projectService.GetProject(user, projectId, ct);
        if (!int.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) || project.OwnerId != userId)
        {
            throw new ApiException(403, "Only the project owner can manage teams.");
        }
        return project;
    }

    private async Task<Team> FindTeam(ClaimsPrincipal user, int projectId, int id, CancellationToken ct)
    {
        await _projectService.GetProject(user, projectId, ct);
        return await _context.Teams.SingleOrDefaultAsync(team => team.Id == id && team.ProjectId == projectId, ct)
            ?? throw new ApiException(404, "Team not found.");
    }

    // Team members and leads must already have active access to the project.
    private async Task ValidateParticipant(ProjectResponse project, int userId, CancellationToken ct)
    {
        var eligible = await _context.Users.AnyAsync(member => member.Id == userId &&
            member.OrganizationId == project.OrganizationId && member.IsActive && !member.IsDeleted &&
            (member.Id == project.OwnerId || member.ProjectMemberships.Any(membership =>
                membership.ProjectId == project.Id && !membership.IsBlocked)), ct);
        if (!eligible)
        {
            throw new ApiException(404, "An active project participant was not found.");
        }
    }

    // Returns a paginated team list with member counts and lead display names.
    public async Task<IReadOnlyList<TeamResponse>> ListTeams(ClaimsPrincipal user, int projectId, int page, int pageSize, CancellationToken ct)
    {
        await _projectService.GetProject(user, projectId, ct);
        return await _context.Teams
            .AsNoTracking()
            .Where(team => team.ProjectId == projectId)
            .OrderBy(team => team.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(team => new TeamResponse(team.Id, projectId, team.Name, team.Description,
                team.LeadUserId, team.LeadUser == null ? null : team.LeadUser.FullName,
                team.Members.Count, team.CreatedAt, team.UpdatedAt))
            .ToListAsync(ct);
    }

    // Returns one team belonging to the requested project.
    public async Task<TeamResponse> GetTeam(ClaimsPrincipal user, int projectId, int id, CancellationToken ct)
    {
        await _projectService.GetProject(user, projectId, ct);
        return await _context.Teams
            .AsNoTracking()
            .Where(team => team.Id == id && team.ProjectId == projectId)
            .Select(team => new TeamResponse(team.Id, projectId, team.Name, team.Description,
                team.LeadUserId, team.LeadUser == null ? null : team.LeadUser.FullName,
                team.Members.Count, team.CreatedAt, team.UpdatedAt))
            .SingleOrDefaultAsync(ct)
            ?? throw new ApiException(404, "Team not found.");
    }

    // Creates a project-scoped team from the request DTO.
    public async Task<TeamResponse> CreateTeam(ClaimsPrincipal user, int projectId, TeamRequest request, CancellationToken ct)
    {
        var project = await RequireOwner(user, projectId, ct);
        if (request.LeadUserId.HasValue)
        {
            await ValidateParticipant(project, request.LeadUserId.Value, ct);
        }
        var team = new Team
        {
            ProjectId = projectId,
            OrganizationId = project.OrganizationId,
            Name = request.Name.Trim(),
            Description = request.Description,
            LeadUserId = request.LeadUserId
        };
        _context.Teams.Add(team);
        await _context.SaveChangesAsync(ct);
        return await GetTeam(user, projectId, team.Id, ct);
    }

    // Updates team details without changing its project or organization.
    public async Task<TeamResponse> UpdateTeam(ClaimsPrincipal user, int projectId, int id, TeamRequest request, CancellationToken ct)
    {
        var project = await RequireOwner(user, projectId, ct);
        var team = await FindTeam(user, projectId, id, ct);
        if (request.LeadUserId.HasValue)
        {
            await ValidateParticipant(project, request.LeadUserId.Value, ct);
        }
        team.Name = request.Name.Trim();
        team.Description = request.Description;
        team.LeadUserId = request.LeadUserId;
        team.UpdatedAt = DateTimeOffset.UtcNow;
        await _context.SaveChangesAsync(ct);
        return await GetTeam(user, projectId, id, ct);
    }

    // Removes team members and their team in one database save.
    public async Task DeleteTeam(ClaimsPrincipal user, int projectId, int id, CancellationToken ct)
    {
        await RequireOwner(user, projectId, ct);
        var team = await FindTeam(user, projectId, id, ct);
        var members = await _context.TeamMembers.Where(member => member.TeamId == id).ToListAsync(ct);
        _context.TeamMembers.RemoveRange(members);
        _context.Teams.Remove(team);
        await _context.SaveChangesAsync(ct);
    }

    // Returns paginated member display data without exposing user entities.
    public async Task<IReadOnlyList<TeamMemberResponse>> ListMembers(ClaimsPrincipal user, int projectId, int teamId, int page, int pageSize, CancellationToken ct)
    {
        await FindTeam(user, projectId, teamId, ct);
        return await _context.TeamMembers
            .AsNoTracking()
            .Where(member => member.TeamId == teamId)
            .OrderBy(member => member.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(member => new TeamMemberResponse(member.Id, member.TeamId, member.UserId,
                member.User.FullName, member.User.AvatarUrl, member.User.JobTitle, member.User.IsActive,
                member.RoleInTeam, member.JoinedAt))
            .ToListAsync(ct);
    }

    // Returns one team membership by its user identifier.
    public async Task<TeamMemberResponse> GetMember(ClaimsPrincipal user, int projectId, int teamId, int userId, CancellationToken ct)
    {
        await FindTeam(user, projectId, teamId, ct);
        return await _context.TeamMembers
            .AsNoTracking()
            .Where(member => member.TeamId == teamId && member.UserId == userId)
            .Select(member => new TeamMemberResponse(member.Id, member.TeamId, member.UserId,
                member.User.FullName, member.User.AvatarUrl, member.User.JobTitle, member.User.IsActive,
                member.RoleInTeam, member.JoinedAt))
            .SingleOrDefaultAsync(ct)
            ?? throw new ApiException(404, "Team member not found.");
    }

    // Adds an eligible participant once per team.
    public async Task<TeamMemberResponse> AddMember(ClaimsPrincipal user, int projectId, int teamId, AddTeamMemberRequest request, CancellationToken ct)
    {
        var project = await RequireOwner(user, projectId, ct);
        await FindTeam(user, projectId, teamId, ct);
        await ValidateParticipant(project, request.UserId, ct);
        if (await _context.TeamMembers.AnyAsync(member => member.TeamId == teamId && member.UserId == request.UserId, ct))
        {
            throw new ApiException(409, "Team member already exists.");
        }
        var member = new TeamMember
        {
            TeamId = teamId,
            UserId = request.UserId,
            RoleInTeam = request.RoleInTeam
        };
        _context.TeamMembers.Add(member);
        await _context.SaveChangesAsync(ct);
        return await GetMember(user, projectId, teamId, request.UserId, ct);
    }

    // Updates team-role metadata without granting project-management permissions.
    public async Task<TeamMemberResponse> UpdateMember(ClaimsPrincipal user, int projectId, int teamId, int userId, UpdateTeamMemberRequest request, CancellationToken ct)
    {
        var project = await RequireOwner(user, projectId, ct);
        await FindTeam(user, projectId, teamId, ct);
        await ValidateParticipant(project, userId, ct);
        var member = await _context.TeamMembers.SingleOrDefaultAsync(member =>
            member.TeamId == teamId && member.UserId == userId, ct)
            ?? throw new ApiException(404, "Team member not found.");
        member.RoleInTeam = request.RoleInTeam;
        await _context.SaveChangesAsync(ct);
        return await GetMember(user, projectId, teamId, userId, ct);
    }

    // Removes a team membership and clears leadership when necessary.
    public async Task RemoveMember(ClaimsPrincipal user, int projectId, int teamId, int userId, CancellationToken ct)
    {
        await RequireOwner(user, projectId, ct);
        var team = await FindTeam(user, projectId, teamId, ct);
        var member = await _context.TeamMembers.SingleOrDefaultAsync(member =>
            member.TeamId == teamId && member.UserId == userId, ct)
            ?? throw new ApiException(404, "Team member not found.");
        _context.TeamMembers.Remove(member);
        if (team.LeadUserId == userId)
        {
            team.LeadUserId = null;
            team.UpdatedAt = DateTimeOffset.UtcNow;
        }
        await _context.SaveChangesAsync(ct);
    }
}
