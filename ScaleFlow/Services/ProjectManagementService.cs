using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.DTOs;
using ScaleFlow.Middleware;
using ScaleFlow.Models;

namespace ScaleFlow.Services;

public class ProjectManagementService(ScaleFlowDbContext db) : IProjectService, ITaskService
{
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
        await db.Users.SingleOrDefaultAsync(x => x.Id == userId && x.IsActive && !x.IsDeleted && !x.Organization.IsDeleted, ct)
        ?? throw new ApiException(401, "An active user is required.");

    private IQueryable<Project> Accessible(User actor) => db.Projects.Where(x => x.OrganizationId == actor.OrganizationId &&
        (x.OwnerId == actor.Id || x.Members.Any(m => m.UserId == actor.Id && !m.IsBlocked)));

    private async Task<Project> FindProject(int userId, int id, CancellationToken ct, bool ownerOnly = false)
    {
        var actor = await Actor(userId, ct);
        var project = await Accessible(actor).SingleOrDefaultAsync(x => x.Id == id, ct)
            ?? throw new ApiException(404, "Project not found.");
        if (ownerOnly && project.OwnerId != userId) throw new ApiException(403, "Only the project owner can modify this project.");
        return project;
    }

    public async Task<IReadOnlyList<ProjectResponse>> ListProjects(ClaimsPrincipal user, int page, int pageSize, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var actor = await Actor(userId, ct);
        return (await Accessible(actor).AsNoTracking().OrderBy(x => x.Id).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct))
            .Select(Map).ToArray();
    }
    public async Task<ProjectResponse> GetProject(ClaimsPrincipal user, int id, CancellationToken ct)
    {
        var userId = GetUserId(user);
        return Map(await FindProject(userId, id, ct));
    }

    public async Task<ProjectResponse> CreateProject(ClaimsPrincipal user, ProjectRequest request, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var actor = await Actor(userId, ct);
        var project = new Project { OrganizationId = actor.OrganizationId, OwnerId = actor.Id };
        Apply(project, request);
        db.Projects.Add(project);
        await db.SaveChangesAsync(ct);
        return Map(project);
    }
    public async Task<ProjectResponse> UpdateProject(ClaimsPrincipal user, int id, ProjectRequest request, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var project = await FindProject(userId, id, ct, true);
        Apply(project, request);
        project.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);
        return Map(project);
    }
    public async Task DeleteProject(ClaimsPrincipal user, int id, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var project = await FindProject(userId, id, ct, true);
        project.IsDeleted = true;
        project.DeletedBy = userId;
        project.DeletedAt = project.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);
    }
    public async Task<IReadOnlyList<TaskResponse>> ListTasks(ClaimsPrincipal user, int projectId, int page, int pageSize, CancellationToken ct)
    {
        var userId = GetUserId(user);
        await FindProject(userId, projectId, ct);
        return (await db.ProjectTasks.AsNoTracking().Where(x => x.ProjectId == projectId).OrderBy(x => x.Id)
            .Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct)).Select(Map).ToArray();
    }
    private async Task<ProjectTask> FindTask(int userId, int projectId, int id, CancellationToken ct)
    {
        await FindProject(userId, projectId, ct);
        return await db.ProjectTasks.SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == projectId, ct)
            ?? throw new ApiException(404, "Task not found.");
    }
    public async Task<TaskResponse> GetTask(ClaimsPrincipal user, int projectId, int id, CancellationToken ct)
    {
        var userId = GetUserId(user);
        return Map(await FindTask(userId, projectId, id, ct));
    }

    public async Task<TaskResponse> CreateTask(ClaimsPrincipal user, int projectId, TaskRequest request, CancellationToken ct)
    {
        var userId = GetUserId(user);
        await FindProject(userId, projectId, ct);
        var task = new ProjectTask { ProjectId = projectId, CreatedBy = userId, UpdatedBy = userId };
        Apply(task, request);
        db.ProjectTasks.Add(task);
        await db.SaveChangesAsync(ct);
        return Map(task);
    }
    public async Task<TaskResponse> UpdateTask(ClaimsPrincipal user, int projectId, int id, TaskRequest request, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var task = await FindTask(userId, projectId, id, ct);
        if (task.Status != request.Status)
            db.TaskStatusHistories.Add(new TaskStatusHistory { TaskId = id, FromStatus = task.Status, ToStatus = request.Status, ChangedBy = userId });
        Apply(task, request);
        task.UpdatedBy = userId;
        task.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);
        return Map(task);
    }
    public async Task DeleteTask(ClaimsPrincipal user, int projectId, int id, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var task = await FindTask(userId, projectId, id, ct);
        task.IsDeleted = true;
        task.DeletedBy = task.UpdatedBy = userId;
        task.DeletedAt = task.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);
    }
    private static void Apply(Project x, ProjectRequest r)
    {
        x.Name = r.Name.Trim(); x.Description = r.Description; x.Status = r.Status; x.Priority = r.Priority;
        x.Budget = r.Budget; x.StartDate = r.StartDate; x.EndDate = r.EndDate;
        x.IsArchived = r.Status == ProjectStatus.Archived;
    }
    private static void Apply(ProjectTask x, TaskRequest r)
    {
        x.Title = r.Title.Trim(); x.Description = r.Description; x.Status = r.Status; x.Priority = r.Priority;
        x.Type = r.Type; x.PlannedStart = r.PlannedStart; x.PlannedEnd = r.PlannedEnd;
        x.EstimatedHours = r.EstimatedHours; x.CompletionPercent = r.CompletionPercent;
    }
    private static ProjectResponse Map(Project x) => new(x.Id, x.OrganizationId, x.OwnerId, x.Name, x.Description,
        x.Status, x.Priority, x.Budget, x.StartDate, x.EndDate, x.CreatedAt, x.UpdatedAt);
    private static TaskResponse Map(ProjectTask x) => new(x.Id, x.ProjectId, x.Title, x.Description, x.Status, x.Priority,
        x.Type, x.PlannedStart, x.PlannedEnd, x.EstimatedHours, x.CompletionPercent, x.CreatedBy, x.UpdatedBy, x.CreatedAt, x.UpdatedAt);
}
