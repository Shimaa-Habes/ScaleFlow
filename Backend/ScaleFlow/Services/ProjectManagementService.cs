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

    public ProjectManagementService(ScaleFlowDbContext context, IHubContext<ScaleFlowHub>? hubContext = null)
    {
        _context = context;
        _hubContext = hubContext;
    }

    private static int GetUserId(ClaimsPrincipal user)
    {
        var userIdClaim = user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (user.Identity?.IsAuthenticated != true || !int.TryParse(userIdClaim, out var userId) || userId <= 0)
        {
            throw new ApiException(401, "Invalid user identity.");
        }

        return userId;
    }

    private async Task<User> Actor(int userId, CancellationToken ct) =>
        await _context.Users.SingleOrDefaultAsync(x => x.Id == userId && x.IsActive && !x.IsDeleted && !x.Organization.IsDeleted, ct)
        ?? throw new ApiException(401, "An active user is required.");

    private IQueryable<Project> Accessible(User actor) => _context.Projects.Where(x => x.OrganizationId == actor.OrganizationId &&
        (x.OwnerId == actor.Id || x.Members.Any(m => m.UserId == actor.Id && !m.IsBlocked)));

    private async Task<Project> FindProject(int userId, int id, CancellationToken ct, bool ownerOnly = false)
    {
        var actor = await Actor(userId, ct);
        var project = await Accessible(actor).SingleOrDefaultAsync(x => x.Id == id, ct)
            ?? throw new ApiException(404, "Project not found.");
        if (ownerOnly && project.OwnerId != userId) throw new ApiException(403, "Only the project owner can modify this project.");
        return project;
    }

    // Returns a paginated list of accessible projects as response DTOs.
    public async Task<IReadOnlyList<ProjectResponse>> ListProjects(ClaimsPrincipal user, int page, int pageSize, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var actor = await Actor(userId, ct);
        return await Accessible(actor)
            .AsNoTracking()
            .OrderBy(project => project.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(project => new ProjectResponse(project.Id, project.OrganizationId, project.OwnerId, project.Name,
                project.Description, project.Status, project.Priority, project.Budget, project.StartDate,
                project.EndDate, project.CreatedAt, project.UpdatedAt))
            .ToListAsync(ct);
    }
    // Returns one accessible project as a response DTO.
    public async Task<ProjectResponse> GetProject(ClaimsPrincipal user, int id, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var actor = await Actor(userId, ct);
        return await Accessible(actor)
            .AsNoTracking()
            .Where(project => project.Id == id)
            .Select(project => new ProjectResponse(project.Id, project.OrganizationId, project.OwnerId, project.Name,
                project.Description, project.Status, project.Priority, project.Budget, project.StartDate,
                project.EndDate, project.CreatedAt, project.UpdatedAt))
            .SingleOrDefaultAsync(ct)
            ?? throw new ApiException(404, "Project not found.");
    }

    // Creates a project from the request DTO.
    public async Task<ProjectResponse> CreateProject(ClaimsPrincipal user, ProjectRequest request, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var actor = await Actor(userId, ct);
        var project = new Project { OrganizationId = actor.OrganizationId, OwnerId = actor.Id };
        project.Name = request.Name.Trim();
        project.Description = request.Description;
        project.Status = request.Status;
        project.Priority = request.Priority;
        project.Budget = request.Budget;
        project.StartDate = request.StartDate;
        project.EndDate = request.EndDate;
        project.IsArchived = request.Status == ProjectStatus.Archived;
        _context.Projects.Add(project);
        await _context.SaveChangesAsync(ct);
        return new ProjectResponse(project.Id, project.OrganizationId, project.OwnerId, project.Name,
                project.Description, project.Status, project.Priority, project.Budget, project.StartDate,
                project.EndDate, project.CreatedAt, project.UpdatedAt);
    }
    // Updates a project owned by the authenticated user.
    public async Task<ProjectResponse> UpdateProject(ClaimsPrincipal user, int id, ProjectRequest request, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var project = await FindProject(userId, id, ct, true);
        project.Name = request.Name.Trim();
        project.Description = request.Description;
        project.Status = request.Status;
        project.Priority = request.Priority;
        project.Budget = request.Budget;
        project.StartDate = request.StartDate;
        project.EndDate = request.EndDate;
        project.IsArchived = request.Status == ProjectStatus.Archived;
        project.UpdatedAt = DateTimeOffset.UtcNow;
        await _context.SaveChangesAsync(ct);
        var updatedResponse = new ProjectResponse(project.Id, project.OrganizationId, project.OwnerId, project.Name,
                project.Description, project.Status, project.Priority, project.Budget, project.StartDate,
                project.EndDate, project.CreatedAt, project.UpdatedAt);
        if (_hubContext is not null)
        {
            await _hubContext.Clients.Group($"project_{id}").SendAsync("ProjectUpdated", updatedResponse, ct);
        }
        return updatedResponse;
    }
    // Soft-deletes a project owned by the authenticated user.
    public async Task DeleteProject(ClaimsPrincipal user, int id, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var project = await FindProject(userId, id, ct, true);
        project.IsDeleted = true;
        project.DeletedBy = userId;
        project.DeletedAt = project.UpdatedAt = DateTimeOffset.UtcNow;
        await _context.SaveChangesAsync(ct);
        if (_hubContext is not null)
        {
            await _hubContext.Clients.Group($"project_{id}").SendAsync("ProjectDeleted", new { projectId = id }, ct);
        }
    }
}
