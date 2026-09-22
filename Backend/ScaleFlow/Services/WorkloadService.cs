using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.DTOs;
using ScaleFlow.Hubs;
using ScaleFlow.Middleware;
using ScaleFlow.Models;
using TaskStatus = ScaleFlow.Models.TaskStatus;

namespace ScaleFlow.Services;

public class WorkloadService : IWorkloadService
{
    private readonly ScaleFlowDbContext _context;
    private readonly IProjectService _projectService;
    private readonly INotificationService _notificationService;
    private readonly IHubContext<ScaleFlowHub> _hubContext;

    public WorkloadService(
        ScaleFlowDbContext context,
        IProjectService projectService,
        INotificationService notificationService,
        IHubContext<ScaleFlowHub> hubContext)
    {
        _context = context;
        _projectService = projectService;
        _notificationService = notificationService;
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

    private async Task<ProjectTask> FindTask(int projectId, int taskId, CancellationToken ct)
    {
        return await _context.ProjectTasks
            .SingleOrDefaultAsync(t => t.Id == taskId && t.ProjectId == projectId && !t.IsDeleted, ct)
            ?? throw new ApiException(404, "Task not found.");
    }

    private async Task ValidateParticipant(ProjectResponse project, int userId, CancellationToken ct)
    {
        var isParticipant = await _context.Users.AnyAsync(u =>
            u.Id == userId &&
            u.OrganizationId == project.OrganizationId &&
            u.IsActive &&
            !u.IsDeleted &&
            (u.Id == project.OwnerId || u.ProjectMemberships.Any(m => m.ProjectId == project.Id && !m.IsBlocked)),
            ct);

        if (!isParticipant)
        {
            throw new ApiException(404, "An active project participant was not found.");
        }
    }

    public async Task<ProjectWorkloadSummaryResponse> GetProjectWorkload(ClaimsPrincipal user, int projectId, CancellationToken ct)
    {
        var project = await _projectService.GetProject(user, projectId, ct);

        // Fetch eligible participants: owner + active non-blocked members
        var memberUsers = await _context.Users
            .AsNoTracking()
            .Where(u => u.OrganizationId == project.OrganizationId && u.IsActive && !u.IsDeleted &&
                        (u.Id == project.OwnerId || u.ProjectMemberships.Any(m => m.ProjectId == projectId && !m.IsBlocked)))
            .ToListAsync(ct);

        // Fetch all assignments and tasks in the project
        var assignments = await _context.TaskAssignments
            .AsNoTracking()
            .Where(a => a.Task.ProjectId == projectId && !a.Task.IsDeleted)
            .Include(a => a.Task)
            .ToListAsync(ct);

        var allProjectTasks = await _context.ProjectTasks
            .AsNoTracking()
            .Where(t => t.ProjectId == projectId && !t.IsDeleted)
            .ToListAsync(ct);

        var memberResponses = new List<MemberWorkloadResponse>();
        var now = DateTimeOffset.UtcNow;

        foreach (var member in memberUsers)
        {
            var userTasks = assignments
                .Where(a => a.UserId == member.Id)
                .Select(a => a.Task)
                .DistinctBy(t => t.Id)
                .ToList();

            var assignedCount = userTasks.Count;
            var plannedHours = userTasks.Sum(t => t.EstimatedHours ?? 0);
            var actualHours = userTasks.Sum(t => t.ActualHours ?? 0);
            var completedCount = userTasks.Count(t => t.Status == TaskStatus.Done);
            var inProgressCount = userTasks.Count(t => t.Status == TaskStatus.InProgress);
            var overdueCount = userTasks.Count(t => t.Status != TaskStatus.Done && t.PlannedEnd.HasValue && t.PlannedEnd.Value < now);

            // Utilization ratio based on 40 standard weekly hours benchmark
            var utilizationRatio = Math.Round((plannedHours / 40m) * 100m, 2);

            string status;
            if (utilizationRatio > 100m || plannedHours > 45m || (assignedCount >= 8 && utilizationRatio >= 80m))
            {
                status = "Overloaded";
            }
            else if (utilizationRatio < 40m && assignedCount <= 1)
            {
                status = "Underutilized";
            }
            else
            {
                status = "Normal";
            }

            memberResponses.Add(new MemberWorkloadResponse(
                member.Id,
                member.FullName,
                member.AvatarUrl,
                member.JobTitle,
                assignedCount,
                plannedHours,
                actualHours,
                completedCount,
                inProgressCount,
                overdueCount,
                utilizationRatio,
                status));
        }

        var assignedTaskIds = assignments.Select(a => a.TaskId).ToHashSet();
        var unassignedCount = allProjectTasks.Count(t => !assignedTaskIds.Contains(t.Id));
        var avgUtilization = memberResponses.Count > 0
            ? Math.Round(memberResponses.Average(m => m.UtilizationRatio), 2)
            : 0m;
        var overloadedCount = memberResponses.Count(m => m.WorkloadStatus == "Overloaded");
        var underutilizedCount = memberResponses.Count(m => m.WorkloadStatus == "Underutilized");

        return new ProjectWorkloadSummaryResponse(
            projectId,
            memberResponses.Count,
            assignedTaskIds.Count,
            unassignedCount,
            avgUtilization,
            overloadedCount,
            underutilizedCount,
            memberResponses.OrderByDescending(m => m.UtilizationRatio).ToList());
    }

    public async Task<MemberWorkloadResponse> GetMemberWorkload(ClaimsPrincipal user, int projectId, int userId, CancellationToken ct)
    {
        var summary = await GetProjectWorkload(user, projectId, ct);
        var member = summary.Members.FirstOrDefault(m => m.UserId == userId)
            ?? throw new ApiException(404, "Member workload not found in project.");

        return member;
    }

    public async Task<TaskAssignmentResponse> AssignTask(
        ClaimsPrincipal user, int projectId, int taskId, AssignTaskRequest request, CancellationToken ct)
    {
        var project = await _projectService.GetProject(user, projectId, ct);
        var callerUserId = GetUserId(user);
        var task = await FindTask(projectId, taskId, ct);
        await ValidateParticipant(project, request.AssigneeUserId, ct);

        var existing = await _context.TaskAssignments
            .SingleOrDefaultAsync(a => a.TaskId == taskId && a.UserId == request.AssigneeUserId, ct);

        if (existing is not null)
        {
            throw new ApiException(409, "Task is already assigned to this user.");
        }

        var assignment = new TaskAssignment
        {
            TaskId = taskId,
            UserId = request.AssigneeUserId,
            AssignedBy = callerUserId,
            IsPrimary = request.IsPrimary,
            AssignedAt = DateTimeOffset.UtcNow
        };

        _context.TaskAssignments.Add(assignment);
        await _context.SaveChangesAsync(ct);

        var assigneeUser = await _context.Users.SingleAsync(u => u.Id == request.AssigneeUserId, ct);

        var response = new TaskAssignmentResponse(
            assignment.Id,
            assignment.TaskId,
            assignment.UserId,
            assigneeUser.FullName,
            assignment.AssignedBy,
            assignment.IsPrimary,
            assignment.AssignedAt);

        // Notify assignee if caller is different
        if (request.AssigneeUserId != callerUserId)
        {
            await _notificationService.CreateNotification(
                request.AssigneeUserId,
                callerUserId,
                "TaskAssigned",
                "New Task Assigned",
                $"You have been assigned to task: '{task.Title}' in project '{project.Name}'.",
                "Task",
                taskId,
                projectId,
                ct);
        }

        // Real-time broadcast to project group
        await _hubContext.Clients.Group($"project_{projectId}")
            .SendAsync("TaskAssignmentCreated", response, ct);

        return response;
    }

    public async Task RemoveTaskAssignment(ClaimsPrincipal user, int projectId, int taskId, int assigneeUserId, CancellationToken ct)
    {
        await _projectService.GetProject(user, projectId, ct);
        await FindTask(projectId, taskId, ct);

        var assignment = await _context.TaskAssignments
            .SingleOrDefaultAsync(a => a.TaskId == taskId && a.UserId == assigneeUserId, ct)
            ?? throw new ApiException(404, "Task assignment not found.");

        _context.TaskAssignments.Remove(assignment);
        await _context.SaveChangesAsync(ct);

        // Real-time broadcast
        await _hubContext.Clients.Group($"project_{projectId}")
            .SendAsync("TaskAssignmentRemoved", new { taskId, userId = assigneeUserId }, ct);
    }

    public async Task<IReadOnlyList<TaskAssignmentResponse>> ListTaskAssignments(
        ClaimsPrincipal user, int projectId, int taskId, CancellationToken ct)
    {
        await _projectService.GetProject(user, projectId, ct);
        await FindTask(projectId, taskId, ct);

        return await _context.TaskAssignments
            .AsNoTracking()
            .Where(a => a.TaskId == taskId)
            .OrderBy(a => a.Id)
            .Select(a => new TaskAssignmentResponse(
                a.Id,
                a.TaskId,
                a.UserId,
                a.User.FullName,
                a.AssignedBy,
                a.IsPrimary,
                a.AssignedAt))
            .ToListAsync(ct);
    }
}
