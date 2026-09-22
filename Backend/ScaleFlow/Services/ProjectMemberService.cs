using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.DTOs;
using ScaleFlow.Middleware;
using ScaleFlow.Models;

namespace ScaleFlow.Services;

public class ProjectMemberService : IProjectMemberService
{
    private readonly ScaleFlowDbContext _context;
    private readonly IProjectService _projectService;

    public ProjectMemberService(ScaleFlowDbContext context, IProjectService projectService)
    {
        _context = context;
        _projectService = projectService;
    }

    private async Task<ProjectResponse> RequireOwner(ClaimsPrincipal user, int projectId, CancellationToken ct)
    {
        var project = await _projectService.GetProject(user, projectId, ct);
        if (!int.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) || project.OwnerId != userId)
        {
            throw new ApiException(403, "Only the project owner can manage project members.");
        }
        return project;
    }

    // Returns member display data without exposing Identity entities.
    public async Task<IReadOnlyList<ProjectMemberResponse>> ListMembers(ClaimsPrincipal user, int projectId, int page, int pageSize, CancellationToken ct)
    {
        await _projectService.GetProject(user, projectId, ct);
        return await _context.ProjectMembers
            .AsNoTracking()
            .Where(member => member.ProjectId == projectId)
            .OrderBy(member => member.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(member => new ProjectMemberResponse(member.Id, member.ProjectId, member.UserId,
                member.User.FullName, member.User.AvatarUrl, member.User.JobTitle, member.User.IsActive,
                member.IsBlocked, member.HourlyRate, member.RoleOverride, member.JoinedAt))
            .ToListAsync(ct);
    }

    // Returns one membership by its user identifier.
    public async Task<ProjectMemberResponse> GetMember(ClaimsPrincipal user, int projectId, int userId, CancellationToken ct)
    {
        await _projectService.GetProject(user, projectId, ct);
        return await _context.ProjectMembers
            .AsNoTracking()
            .Where(member => member.ProjectId == projectId && member.UserId == userId)
            .Select(member => new ProjectMemberResponse(member.Id, member.ProjectId, member.UserId,
                member.User.FullName, member.User.AvatarUrl, member.User.JobTitle, member.User.IsActive,
                member.IsBlocked, member.HourlyRate, member.RoleOverride, member.JoinedAt))
            .SingleOrDefaultAsync(ct)
            ?? throw new ApiException(404, "Project member not found.");
    }

    // Adds an active user from the project's organization.
    public async Task<ProjectMemberResponse> AddMember(ClaimsPrincipal user, int projectId, AddProjectMemberRequest request, CancellationToken ct)
    {
        var project = await RequireOwner(user, projectId, ct);
        if (request.UserId == project.OwnerId)
        {
            throw new ApiException(400, "The project owner already has access.");
        }
        if (!await _context.Users.AnyAsync(member => member.Id == request.UserId &&
            member.OrganizationId == project.OrganizationId && member.IsActive && !member.IsDeleted, ct))
        {
            throw new ApiException(404, "An active organization user was not found.");
        }
        if (await _context.ProjectMembers.AnyAsync(member => member.ProjectId == projectId && member.UserId == request.UserId, ct))
        {
            throw new ApiException(409, "Project member already exists.");
        }

        var member = new ProjectMember
        {
            ProjectId = projectId,
            UserId = request.UserId,
            HourlyRate = request.HourlyRate,
            RoleOverride = request.RoleOverride
        };
        _context.ProjectMembers.Add(member);
        await _context.SaveChangesAsync(ct);
        return await GetMember(user, projectId, request.UserId, ct);
    }

    // Updates membership metadata and revokes team links when blocked.
    public async Task<ProjectMemberResponse> UpdateMember(ClaimsPrincipal user, int projectId, int userId, UpdateProjectMemberRequest request, CancellationToken ct)
    {
        var project = await RequireOwner(user, projectId, ct);
        if (userId == project.OwnerId)
        {
            throw new ApiException(400, "The project owner's membership cannot be changed.");
        }
        var member = await _context.ProjectMembers.SingleOrDefaultAsync(member =>
            member.ProjectId == projectId && member.UserId == userId, ct)
            ?? throw new ApiException(404, "Project member not found.");
        member.IsBlocked = request.IsBlocked;
        member.HourlyRate = request.HourlyRate;
        member.RoleOverride = request.RoleOverride;
        member.UpdatedAt = DateTimeOffset.UtcNow;
        if (request.IsBlocked)
        {
            await RemoveTeamLinks(projectId, userId, ct);
        }
        await _context.SaveChangesAsync(ct);
        return await GetMember(user, projectId, userId, ct);
    }

    // Removes the membership and its project-team links atomically.
    public async Task RemoveMember(ClaimsPrincipal user, int projectId, int userId, CancellationToken ct)
    {
        var project = await RequireOwner(user, projectId, ct);
        if (userId == project.OwnerId)
        {
            throw new ApiException(400, "The project owner cannot be removed.");
        }
        var member = await _context.ProjectMembers.SingleOrDefaultAsync(member =>
            member.ProjectId == projectId && member.UserId == userId, ct)
            ?? throw new ApiException(404, "Project member not found.");
        await RemoveTeamLinks(projectId, userId, ct);
        _context.ProjectMembers.Remove(member);
        await _context.SaveChangesAsync(ct);
    }

    // Prevents removed or blocked members from retaining team membership or leadership.
    private async Task RemoveTeamLinks(int projectId, int userId, CancellationToken ct)
    {
        var members = await _context.TeamMembers
            .Where(member => member.Team.ProjectId == projectId && member.UserId == userId).ToListAsync(ct);
        _context.TeamMembers.RemoveRange(members);
        var teams = await _context.Teams.Where(team => team.ProjectId == projectId && team.LeadUserId == userId).ToListAsync(ct);
        foreach (var team in teams)
        {
            team.LeadUserId = null;
            team.UpdatedAt = DateTimeOffset.UtcNow;
        }
    }
}
