using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.Constants;
using ScaleFlow.Models;

namespace ScaleFlow.Controllers;

[Authorize]
public abstract class ProjectControllerBase : ControllerBase
{
    protected readonly ScaleFlowDbContext DbContext;

    protected ProjectControllerBase(ScaleFlowDbContext dbContext)
    {
        DbContext = dbContext;
    }

    protected int? CurrentUserId => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId)
        ? userId
        : null;

    protected bool IsAuthenticated => User.Identity?.IsAuthenticated == true;
    protected bool IsProjectManager => User.IsInRole(RoleConstants.ProjectManager);
    protected bool IsTeamLeader => User.IsInRole(RoleConstants.TeamLeader);
    protected bool IsTeamMember => User.IsInRole(RoleConstants.TeamMember);
    protected bool IsClient => User.IsInRole(RoleConstants.Client);

    protected async Task<int?> GetCurrentUserOrganizationIdAsync(CancellationToken cancellationToken)
    {
        if (CurrentUserId is not int userId)
        {
            return null;
        }

        return await DbContext.Set<User>()
            .Where(user => user.Id == userId && user.IsActive && !user.IsDeleted)
            .Select(user => (int?)user.OrganizationId)
            .SingleOrDefaultAsync(cancellationToken);
    }

    protected async Task<Project?> FindAccessibleProjectAsync(int projectId, CancellationToken cancellationToken)
    {
        if (CurrentUserId is not int userId)
        {
            return null;
        }

        var organizationId = await GetCurrentUserOrganizationIdAsync(cancellationToken);
        if (organizationId is null)
        {
            return null;
        }

        return await DbContext.Projects
            .Include(project => project.Members)
            .SingleOrDefaultAsync(project =>
                !project.IsDeleted &&
                project.Id == projectId &&
                project.OrganizationId == organizationId.Value &&
                (project.OwnerId == userId || project.Members.Any(member => member.UserId == userId && !member.IsBlocked)),
                cancellationToken);
    }

    protected async Task<Project?> FindProjectInOrganizationAsync(int projectId, CancellationToken cancellationToken)
    {
        var organizationId = await GetCurrentUserOrganizationIdAsync(cancellationToken);
        if (organizationId is null)
        {
            return null;
        }

        return await DbContext.Projects
            .Include(project => project.Members)
            .SingleOrDefaultAsync(project =>
                !project.IsDeleted &&
                project.Id == projectId &&
                project.OrganizationId == organizationId.Value,
                cancellationToken);
    }

    protected async Task<bool> IsProjectMemberAsync(int projectId, CancellationToken cancellationToken)
    {
        if (CurrentUserId is not int userId)
        {
            return false;
        }

        var organizationId = await GetCurrentUserOrganizationIdAsync(cancellationToken);
        if (organizationId is null)
        {
            return false;
        }

        return await DbContext.Projects
            .AnyAsync(project =>
                project.Id == projectId &&
                !project.IsDeleted &&
                project.OrganizationId == organizationId.Value &&
                (project.OwnerId == userId || project.Members.Any(member => member.UserId == userId && !member.IsBlocked)),
                cancellationToken);
    }
}