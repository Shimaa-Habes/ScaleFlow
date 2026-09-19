using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.DTOs;
using ScaleFlow.Middleware;
using ScaleFlow.Models;

namespace ScaleFlow.Services;

public class TaskService : ITaskService
{
    private readonly ScaleFlowDbContext _context;

    public TaskService(ScaleFlowDbContext context)
    {
        _context = context;
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

    private async Task<Project> FindProject(int userId, int id, CancellationToken ct)
    {
        var actor = await Actor(userId, ct);
        var project = await Accessible(actor).SingleOrDefaultAsync(x => x.Id == id, ct)
            ?? throw new ApiException(404, "Project not found.");
        return project;
    }

    // Returns a paginated task list as response DTOs.
    public async Task<IReadOnlyList<TaskResponse>> ListTasks(ClaimsPrincipal user, int projectId, int page, int pageSize, CancellationToken ct)
    {
        var userId = GetUserId(user);
        await FindProject(userId, projectId, ct);
        return await _context.ProjectTasks
            .AsNoTracking()
            .Where(task => task.ProjectId == projectId)
            .OrderBy(task => task.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(task => new TaskResponse(task.Id, task.ProjectId, task.Title, task.Description, task.Status,
                task.Priority, task.Type, task.PlannedStart, task.PlannedEnd, task.EstimatedHours,
                task.CompletionPercent, task.CreatedBy, task.UpdatedBy, task.CreatedAt, task.UpdatedAt))
            .ToListAsync(ct);
    }
    private async Task<ProjectTask> FindTask(int userId, int projectId, int id, CancellationToken ct)
    {
        await FindProject(userId, projectId, ct);
        return await _context.ProjectTasks.SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == projectId, ct)
            ?? throw new ApiException(404, "Task not found.");
    }
    // Returns one accessible task as a response DTO.
    public async Task<TaskResponse> GetTask(ClaimsPrincipal user, int projectId, int id, CancellationToken ct)
    {
        var userId = GetUserId(user);
        await FindProject(userId, projectId, ct);
        return await _context.ProjectTasks
            .AsNoTracking()
            .Where(task => task.Id == id && task.ProjectId == projectId)
            .Select(task => new TaskResponse(task.Id, task.ProjectId, task.Title, task.Description, task.Status,
                task.Priority, task.Type, task.PlannedStart, task.PlannedEnd, task.EstimatedHours,
                task.CompletionPercent, task.CreatedBy, task.UpdatedBy, task.CreatedAt, task.UpdatedAt))
            .SingleOrDefaultAsync(ct)
            ?? throw new ApiException(404, "Task not found.");
    }

    // Creates a task from the request DTO.
    public async Task<TaskResponse> CreateTask(ClaimsPrincipal user, int projectId, TaskRequest request, CancellationToken ct)
    {
        var userId = GetUserId(user);
        await FindProject(userId, projectId, ct);
        var task = new ProjectTask { ProjectId = projectId, CreatedBy = userId, UpdatedBy = userId };
        task.Title = request.Title.Trim();
        task.Description = request.Description;
        task.Status = request.Status;
        task.Priority = request.Priority;
        task.Type = request.Type;
        task.PlannedStart = request.PlannedStart;
        task.PlannedEnd = request.PlannedEnd;
        task.EstimatedHours = request.EstimatedHours;
        task.CompletionPercent = request.CompletionPercent;
        _context.ProjectTasks.Add(task);
        await _context.SaveChangesAsync(ct);
        return new TaskResponse(task.Id, task.ProjectId, task.Title, task.Description, task.Status,
                task.Priority, task.Type, task.PlannedStart, task.PlannedEnd, task.EstimatedHours,
                task.CompletionPercent, task.CreatedBy, task.UpdatedBy, task.CreatedAt, task.UpdatedAt);
    }
    // Updates a task and records status changes.
    public async Task<TaskResponse> UpdateTask(ClaimsPrincipal user, int projectId, int id, TaskRequest request, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var task = await FindTask(userId, projectId, id, ct);
        if (task.Status != request.Status)
            _context.TaskStatusHistories.Add(new TaskStatusHistory { TaskId = id, FromStatus = task.Status, ToStatus = request.Status, ChangedBy = userId });
        task.Title = request.Title.Trim();
        task.Description = request.Description;
        task.Status = request.Status;
        task.Priority = request.Priority;
        task.Type = request.Type;
        task.PlannedStart = request.PlannedStart;
        task.PlannedEnd = request.PlannedEnd;
        task.EstimatedHours = request.EstimatedHours;
        task.CompletionPercent = request.CompletionPercent;
        task.UpdatedBy = userId;
        task.UpdatedAt = DateTimeOffset.UtcNow;
        await _context.SaveChangesAsync(ct);
        return new TaskResponse(task.Id, task.ProjectId, task.Title, task.Description, task.Status,
                task.Priority, task.Type, task.PlannedStart, task.PlannedEnd, task.EstimatedHours,
                task.CompletionPercent, task.CreatedBy, task.UpdatedBy, task.CreatedAt, task.UpdatedAt);
    }
    // Soft-deletes an accessible task.
    public async Task DeleteTask(ClaimsPrincipal user, int projectId, int id, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var task = await FindTask(userId, projectId, id, ct);
        task.IsDeleted = true;
        task.DeletedBy = task.UpdatedBy = userId;
        task.DeletedAt = task.UpdatedAt = DateTimeOffset.UtcNow;
        await _context.SaveChangesAsync(ct);
    }
    // Returns active prerequisites as response DTOs.
    public async Task<IReadOnlyList<TaskDependencyResponse>> ListDependencies(ClaimsPrincipal user, int projectId, int taskId, CancellationToken ct)
    {
        await FindTask(GetUserId(user), projectId, taskId, ct);
        return await _context.TaskDependencies
            .AsNoTracking()
            .Where(dependency => dependency.TaskId == taskId)
            .OrderBy(dependency => dependency.Id)
            .Select(dependency => new TaskDependencyResponse(dependency.Id, dependency.TaskId, dependency.DependsOnTaskId,
                dependency.DependencyType, dependency.LagDays, dependency.Notes, dependency.CreatedAt))
            .ToListAsync(ct);
    }

    private async Task<TaskDependency> FindDependency(int userId, int projectId, int taskId, int id, CancellationToken ct)
    {
        await FindTask(userId, projectId, taskId, ct);
        return await _context.TaskDependencies.SingleOrDefaultAsync(x => x.Id == id && x.TaskId == taskId, ct)
            ?? throw new ApiException(404, "Dependency not found.");
    }

    // Returns one dependency belonging to the requested task.
    public async Task<TaskDependencyResponse> GetDependency(ClaimsPrincipal user, int projectId, int taskId, int id, CancellationToken ct)
    {
        await FindTask(GetUserId(user), projectId, taskId, ct);
        return await _context.TaskDependencies
            .AsNoTracking()
            .Where(dependency => dependency.Id == id && dependency.TaskId == taskId)
            .Select(dependency => new TaskDependencyResponse(dependency.Id, dependency.TaskId, dependency.DependsOnTaskId,
                dependency.DependencyType, dependency.LagDays, dependency.Notes, dependency.CreatedAt))
            .SingleOrDefaultAsync(ct)
            ?? throw new ApiException(404, "Dependency not found.");
    }

    // Creates a dependency after validating the task graph.
    public async Task<TaskDependencyResponse> CreateDependency(ClaimsPrincipal user, int projectId, int taskId, TaskDependencyRequest request, CancellationToken ct)
    {
        // Keep graph validation and writes in the same transaction.
        await using var transaction = _context.Database.IsRelational()
            ? await _context.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable, ct) : null;
        var userId = GetUserId(user);
        await FindTask(userId, projectId, taskId, ct);
        await ValidateDependency(userId, projectId, taskId, request.DependsOnTaskId, null, ct);
        var dependency = new TaskDependency { TaskId = taskId };
        dependency.DependsOnTaskId = request.DependsOnTaskId;
        dependency.DependencyType = request.DependencyType;
        dependency.LagDays = request.LagDays;
        dependency.Notes = request.Notes;
        _context.TaskDependencies.Add(dependency);
        await _context.SaveChangesAsync(ct);
        if (transaction is not null) await transaction.CommitAsync(ct);
        return new TaskDependencyResponse(dependency.Id, dependency.TaskId, dependency.DependsOnTaskId,
                dependency.DependencyType, dependency.LagDays, dependency.Notes, dependency.CreatedAt);
    }

    // Updates a dependency without allowing duplicates or cycles.
    public async Task<TaskDependencyResponse> UpdateDependency(ClaimsPrincipal user, int projectId, int taskId, int id, TaskDependencyRequest request, CancellationToken ct)
    {
        await using var transaction = _context.Database.IsRelational()
            ? await _context.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable, ct) : null;
        var userId = GetUserId(user);
        var dependency = await FindDependency(userId, projectId, taskId, id, ct);
        await ValidateDependency(userId, projectId, taskId, request.DependsOnTaskId, id, ct);
        dependency.DependsOnTaskId = request.DependsOnTaskId;
        dependency.DependencyType = request.DependencyType;
        dependency.LagDays = request.LagDays;
        dependency.Notes = request.Notes;
        await _context.SaveChangesAsync(ct);
        if (transaction is not null) await transaction.CommitAsync(ct);
        return new TaskDependencyResponse(dependency.Id, dependency.TaskId, dependency.DependsOnTaskId,
                dependency.DependencyType, dependency.LagDays, dependency.Notes, dependency.CreatedAt);
    }

    // Removes a dependency belonging to the requested task.
    public async Task DeleteDependency(ClaimsPrincipal user, int projectId, int taskId, int id, CancellationToken ct)
    {
        var dependency = await FindDependency(GetUserId(user), projectId, taskId, id, ct);
        _context.TaskDependencies.Remove(dependency);
        await _context.SaveChangesAsync(ct);
    }

    private async Task ValidateDependency(int userId, int projectId, int taskId, int dependsOnTaskId, int? excludedId, CancellationToken ct)
    {
        if (taskId == dependsOnTaskId) throw new ApiException(400, "A task cannot depend on itself.");
        await FindTask(userId, projectId, dependsOnTaskId, ct);
        var edges = await _context.TaskDependencies.AsNoTracking()
            .Where(x => x.Task!.ProjectId == projectId && (!excludedId.HasValue || x.Id != excludedId.Value))
            .Select(x => new { x.TaskId, x.DependsOnTaskId }).ToListAsync(ct);
        if (edges.Any(x => x.TaskId == taskId && x.DependsOnTaskId == dependsOnTaskId))
            throw new ApiException(409, "Dependency already exists.");

        // Follow prerequisites to detect direct and indirect cycles.
        var graph = edges.ToLookup(x => x.TaskId, x => x.DependsOnTaskId);
        var pending = new Stack<int>();
        var visited = new HashSet<int>();
        pending.Push(dependsOnTaskId);
        while (pending.TryPop(out var current))
        {
            if (current == taskId) throw new ApiException(400, "Dependency would create a cycle.");
            if (!visited.Add(current)) continue;
            foreach (var next in graph[current]) pending.Push(next);
        }
    }

}
