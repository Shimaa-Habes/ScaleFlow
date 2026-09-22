using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.DTOs;
using ScaleFlow.Hubs;
using ScaleFlow.Middleware;
using ScaleFlow.Models;

namespace ScaleFlow.Services;

public class ProjectManagementService : IProjectService
{
    private readonly ScaleFlowDbContext _context;
    private readonly IHubContext<ScaleFlowHub>? _hubContext;

    public ProjectManagementService(
        ScaleFlowDbContext context,
        IHubContext<ScaleFlowHub>? hubContext = null)
    {
        _context = context;
        _hubContext = hubContext;
    }

    private static int GetUserId(ClaimsPrincipal user)
    {
        var userIdClaim = user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (user.Identity?.IsAuthenticated != true ||
            !int.TryParse(userIdClaim, out var userId) ||
            userId <= 0)
        {
            throw new ApiException(401, "Invalid user identity.");
        }

        return userId;
    }

    private async Task<User> Actor(
        int userId,
        CancellationToken ct)
    {
        return await _context.Users
            .SingleOrDefaultAsync(
                x =>
                    x.Id == userId &&
                    x.IsActive &&
                    !x.IsDeleted &&
                    !x.Organization.IsDeleted,
                ct)
            ?? throw new ApiException(
                401,
                "An active user is required.");
    }

    private IQueryable<Project> Accessible(User actor)
    {
        return _context.Projects
            .Where(x =>
                x.OrganizationId == actor.OrganizationId &&
                (
                    x.OwnerId == actor.Id ||
                    x.Members.Any(m =>
                        m.UserId == actor.Id &&
                        !m.IsBlocked)
                ));
    }

    private async Task<Project> FindProject(
        int userId,
        int id,
        CancellationToken ct,
        bool ownerOnly = false)
    {
        var actor = await Actor(userId, ct);

        var project = await Accessible(actor)
            .SingleOrDefaultAsync(
                x => x.Id == id,
                ct)
            ?? throw new ApiException(
                404,
                "Project not found.");

        if (ownerOnly && project.OwnerId != userId)
        {
            throw new ApiException(
                403,
                "Only the project owner can modify this project.");
        }

        return project;
    }

    private static ProjectResponse ToResponse(Project project)
    {
        return new ProjectResponse(
            project.Id,
            project.OrganizationId,
            project.OwnerId,
            project.Name,
            project.Description,
            project.WorkspaceUrl,
            project.Progress,
            project.IsAtRisk,
            project.ImageUrl,
            project.Status,
            project.Priority,
            project.Budget,
            project.StartDate,
            project.EndDate,
            project.CreatedAt,
            project.UpdatedAt);
    }

    // ---------------------------------------------------------
    // GET ALL PROJECTS
    // ---------------------------------------------------------

    public async Task<IReadOnlyList<ProjectResponse>> ListProjects(
        ClaimsPrincipal user,
        int page,
        int pageSize,
        CancellationToken ct)
    {
        var userId = GetUserId(user);
        var actor = await Actor(userId, ct);

        return await Accessible(actor)
            .AsNoTracking()
            .OrderBy(project => project.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(project => new ProjectResponse(
                project.Id,
                project.OrganizationId,
                project.OwnerId,
                project.Name,
                project.Description,
                project.WorkspaceUrl,
                project.Progress,
                project.IsAtRisk,
                project.ImageUrl,
                project.Status,
                project.Priority,
                project.Budget,
                project.StartDate,
                project.EndDate,
                project.CreatedAt,
                project.UpdatedAt))
            .ToListAsync(ct);
    }

    // ---------------------------------------------------------
    // GET PROJECT BY ID
    // ---------------------------------------------------------

    public async Task<ProjectResponse> GetProject(
        ClaimsPrincipal user,
        int id,
        CancellationToken ct)
    {
        var userId = GetUserId(user);
        var actor = await Actor(userId, ct);

        return await Accessible(actor)
            .AsNoTracking()
            .Where(project => project.Id == id)
            .Select(project => new ProjectResponse(
                project.Id,
                project.OrganizationId,
                project.OwnerId,
                project.Name,
                project.Description,
                project.WorkspaceUrl,
                project.Progress,
                project.IsAtRisk,
                project.ImageUrl,
                project.Status,
                project.Priority,
                project.Budget,
                project.StartDate,
                project.EndDate,
                project.CreatedAt,
                project.UpdatedAt))
            .SingleOrDefaultAsync(ct)
            ?? throw new ApiException(
                404,
                "Project not found.");
    }

    // ---------------------------------------------------------
    // CREATE PROJECT
    // ---------------------------------------------------------

    public async Task<ProjectResponse> CreateProject(
        ClaimsPrincipal user,
        ProjectRequest request,
        CancellationToken ct)
    {
        var userId = GetUserId(user);
        var actor = await Actor(userId, ct);

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new ApiException(
                400,
                "Project name is required.");
        }

        if (request.Progress < 0 || request.Progress > 100)
        {
            throw new ApiException(
                400,
                "Progress must be between 0 and 100.");
        }

        if (request.StartDate.HasValue &&
            request.EndDate.HasValue &&
            request.EndDate < request.StartDate)
        {
            throw new ApiException(
                400,
                "End date cannot be earlier than start date.");
        }

        if (request.Budget.HasValue &&
            request.Budget < 0)
        {
            throw new ApiException(
                400,
                "Budget cannot be negative.");
        }

        var project = new Project
        {
            OrganizationId = actor.OrganizationId,
            OwnerId = userId,

            Name = request.Name.Trim(),

            Description =
                string.IsNullOrWhiteSpace(request.Description)
                    ? null
                    : request.Description.Trim(),

            WorkspaceUrl =
                string.IsNullOrWhiteSpace(request.WorkspaceUrl)
                    ? null
                    : request.WorkspaceUrl.Trim(),

            Progress = request.Progress,

            // Explicit project risk selected from Flutter.
            IsAtRisk = request.IsAtRisk,

            Status = request.Status,
            Priority = request.Priority,

            Budget = request.Budget,

            StartDate = request.StartDate,
            EndDate = request.EndDate
        };

        _context.Projects.Add(project);

        await _context.SaveChangesAsync(ct);

        // -----------------------------------------------------
        // ADD PROJECT MEMBERS
        // -----------------------------------------------------

        if (request.MemberUserIds.Count > 0)
        {
            var requestedUserIds = request.MemberUserIds
                .Where(id => id > 0)
                .Distinct()
                .ToList();

            var validUserIds = await _context.Users
                .Where(x =>
                    requestedUserIds.Contains(x.Id) &&
                    x.OrganizationId == actor.OrganizationId &&
                    x.IsActive &&
                    !x.IsDeleted)
                .Select(x => x.Id)
                .ToListAsync(ct);

            foreach (var memberUserId in validUserIds)
            {
                if (memberUserId == actor.Id)
                {
                    continue;
                }

                _context.ProjectMembers.Add(
                    new ProjectMember
                    {
                        ProjectId = project.Id,
                        UserId = memberUserId,
                        JoinedAt = DateTimeOffset.UtcNow,
                        IsBlocked = false
                    });
            }

            await _context.SaveChangesAsync(ct);
        }

        return ToResponse(project);
    }

    // ---------------------------------------------------------
    // UPDATE PROJECT
    // ---------------------------------------------------------

    public async Task<ProjectResponse> UpdateProject(
        ClaimsPrincipal user,
        int id,
        ProjectRequest request,
        CancellationToken ct)
    {
        var userId = GetUserId(user);

        var project = await FindProject(
            userId,
            id,
            ct,
            ownerOnly: true);

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new ApiException(
                400,
                "Project name is required.");
        }

        if (request.Progress < 0 ||
            request.Progress > 100)
        {
            throw new ApiException(
                400,
                "Progress must be between 0 and 100.");
        }

        if (request.StartDate.HasValue &&
            request.EndDate.HasValue &&
            request.EndDate < request.StartDate)
        {
            throw new ApiException(
                400,
                "End date cannot be earlier than start date.");
        }

        if (request.Budget.HasValue &&
            request.Budget < 0)
        {
            throw new ApiException(
                400,
                "Budget cannot be negative.");
        }

        project.Name = request.Name.Trim();

        project.Description =
            string.IsNullOrWhiteSpace(request.Description)
                ? null
                : request.Description.Trim();

        project.WorkspaceUrl =
            string.IsNullOrWhiteSpace(request.WorkspaceUrl)
                ? null
                : request.WorkspaceUrl.Trim();

        project.Progress = request.Progress;

        // Update explicit risk status.
        project.IsAtRisk = request.IsAtRisk;

        project.Status = request.Status;
        project.Priority = request.Priority;
        project.Budget = request.Budget;

        project.StartDate = request.StartDate;
        project.EndDate = request.EndDate;

        project.IsArchived =
            request.Status == ProjectStatus.Archived;

        project.UpdatedAt = DateTimeOffset.UtcNow;

        await _context.SaveChangesAsync(ct);

        // -----------------------------------------------------
        // UPDATE PROJECT MEMBERS
        // -----------------------------------------------------

        var existingMembers = await _context.ProjectMembers
            .Where(x => x.ProjectId == project.Id)
            .ToListAsync(ct);

        _context.ProjectMembers.RemoveRange(existingMembers);

        var requestedUserIds = request.MemberUserIds
            .Where(id => id > 0)
            .Distinct()
            .ToList();

        if (requestedUserIds.Count > 0)
        {
            var validUserIds = await _context.Users
                .Where(x =>
                    requestedUserIds.Contains(x.Id) &&
                    x.OrganizationId == project.OrganizationId &&
                    x.IsActive &&
                    !x.IsDeleted)
                .Select(x => x.Id)
                .ToListAsync(ct);

            foreach (var memberUserId in validUserIds)
            {
                if (memberUserId == project.OwnerId)
                {
                    continue;
                }

                _context.ProjectMembers.Add(
                    new ProjectMember
                    {
                        ProjectId = project.Id,
                        UserId = memberUserId,
                        JoinedAt = DateTimeOffset.UtcNow,
                        IsBlocked = false
                    });
            }
        }

        await _context.SaveChangesAsync(ct);

        var updatedResponse = ToResponse(project);

        // -----------------------------------------------------
        // SIGNALR
        // -----------------------------------------------------

        if (_hubContext is not null)
        {
            await _hubContext.Clients
                .Group($"project_{id}")
                .SendAsync(
                    "ProjectUpdated",
                    updatedResponse,
                    ct);
        }

        return updatedResponse;
    }

    // ---------------------------------------------------------
    // DELETE PROJECT
    // ---------------------------------------------------------

    public async Task DeleteProject(
        ClaimsPrincipal user,
        int id,
        CancellationToken ct)
    {
        var userId = GetUserId(user);

        var project = await FindProject(
            userId,
            id,
            ct,
            ownerOnly: true);

        project.IsDeleted = true;
        project.DeletedBy = userId;
        project.DeletedAt = DateTimeOffset.UtcNow;
        project.UpdatedAt = DateTimeOffset.UtcNow;

        await _context.SaveChangesAsync(ct);

        // -----------------------------------------------------
        // SIGNALR
        // -----------------------------------------------------

        if (_hubContext is not null)
        {
            await _hubContext.Clients
                .Group($"project_{id}")
                .SendAsync(
                    "ProjectDeleted",
                    new { projectId = id },
                    ct);
        }
    }
}