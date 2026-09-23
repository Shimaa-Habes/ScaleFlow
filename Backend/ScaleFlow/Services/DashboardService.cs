using System.Security.Claims;

using Microsoft.EntityFrameworkCore;

using ScaleFlow.DTOs;
using ScaleFlow.Middleware;
using ScaleFlow.Models;

using TaskStatus = ScaleFlow.Models.TaskStatus;

namespace ScaleFlow.Services;

public class DashboardService : IDashboardService
{
    private readonly ScaleFlowDbContext _context;

    public DashboardService(ScaleFlowDbContext context)
    {
        _context = context;
    }

    // ============================================================
    // GET AUTHENTICATED USER ID
    // ============================================================

    private static int GetUserId(ClaimsPrincipal user)
    {
        var userIdClaim = user.FindFirstValue(
            ClaimTypes.NameIdentifier);

        if (user.Identity?.IsAuthenticated != true ||
            !int.TryParse(userIdClaim, out var userId) ||
            userId <= 0)
        {
            throw new ApiException(
                401,
                "Invalid user identity.");
        }

        return userId;
    }

    // ============================================================
    // GET DASHBOARD OVERVIEW
    // ============================================================

    public async Task<DashboardOverviewResponse> GetOverview(
        ClaimsPrincipal user,
        CancellationToken cancellationToken)
    {
        var userId = GetUserId(user);

        // ========================================================
        // AUTHENTICATED USER
        // ========================================================

        var actor = await _context.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                u =>
                    u.Id == userId &&
                    u.IsActive &&
                    !u.IsDeleted,
                cancellationToken);

        if (actor is null)
        {
            throw new ApiException(
                401,
                "User account is inactive or unavailable.");
        }

        // ========================================================
        // ACCESSIBLE PROJECTS
        // ========================================================
        //
        // A user can access a project when:
        // - The project belongs to the user's organization
        // AND
        // - The user is the owner OR an active project member.
        //
        // IsAtRisk is included because the Dashboard must respect
        // the manually saved project risk status.
        // ========================================================

        var accessibleProjects = _context.Projects
            .AsNoTracking()
            .Where(
                p =>
                    p.OrganizationId == actor.OrganizationId &&
                    (
                        p.OwnerId == actor.Id ||
                        p.Members.Any(
                            m =>
                                m.UserId == actor.Id &&
                                !m.IsBlocked)
                    ));

        var projects = await accessibleProjects
            .Select(
                p => new
                {
                    p.Id,
                    p.Name,
                    p.Status,
                    p.IsArchived,
                    p.IsAtRisk
                })
            .ToListAsync(cancellationToken);

        var projectIds = projects
            .Select(p => p.Id)
            .ToHashSet();

        // ========================================================
        // EMPTY DASHBOARD
        // ========================================================

        if (projectIds.Count == 0)
        {
            return new DashboardOverviewResponse(
                ActiveProjects: 0,
                TasksDue: 0,
                OverdueTasks: 0,
                AtRiskProjects: 0,
                CompletedTasks: 0,
                TotalTasks: 0,
                OverallProgress: 0m,
                OnTrackProjects: 0,
                ProjectPerformance:
                    Array.Empty<DashboardProjectPerformanceResponse>(),
                UpcomingDeadlines:
                    Array.Empty<DashboardDeadlineResponse>(),
                TeamWorkload:
                    Array.Empty<DashboardTeamWorkloadResponse>());
        }

        // ========================================================
        // PROJECT TASKS
        // ========================================================

        var tasks = await _context.ProjectTasks
            .AsNoTracking()
            .Where(
                t =>
                    projectIds.Contains(t.ProjectId) &&
                    !t.IsDeleted)
            .Select(
                t => new
                {
                    t.Id,
                    t.ProjectId,
                    t.Title,
                    t.Status,
                    t.PlannedEnd,
                    t.CompletionPercent
                })
            .ToListAsync(cancellationToken);

        var now = DateTimeOffset.UtcNow;
        var today = now.Date;

        // ========================================================
        // ACTIVE PROJECTS
        // ========================================================

        var activeProjects = projects.Count(
            p =>
                p.Status == ProjectStatus.Active &&
                !p.IsArchived);

        // ========================================================
        // TASK METRICS
        // ========================================================

        var totalTasks = tasks.Count;

        var completedTasks = tasks.Count(
            t =>
                t.Status == TaskStatus.Done);

        var nonCancelledTasks = tasks
            .Where(
                t =>
                    t.Status != TaskStatus.Cancelled)
            .ToList();

        // ========================================================
        // OVERALL PROGRESS
        // ========================================================

        var overallProgress = nonCancelledTasks.Count > 0
            ? Math.Round(
                nonCancelledTasks.Average(
                    t =>
                        t.Status == TaskStatus.Done
                            ? 100m
                            : Math.Clamp(
                                t.CompletionPercent ?? 0,
                                0,
                                100)),
                2)
            : 0m;

        // ========================================================
        // TASKS DUE TODAY
        // ========================================================

        var tasksDue = tasks.Count(
            t =>
                t.Status != TaskStatus.Done &&
                t.Status != TaskStatus.Cancelled &&
                t.PlannedEnd.HasValue &&
                t.PlannedEnd.Value.Date == today);

        // ========================================================
        // OVERDUE TASKS
        // ========================================================

        var overdueTasks = tasks.Count(
            t =>
                t.Status != TaskStatus.Done &&
                t.Status != TaskStatus.Cancelled &&
                t.PlannedEnd.HasValue &&
                t.PlannedEnd.Value < now);

        // ========================================================
        // AT-RISK PROJECTS
        // ========================================================
        //
        // A project is considered At Risk when at least one of
        // the following conditions is true:
        //
        // 1. Project.IsAtRisk == true
        // 2. Project has a Blocked task
        // 3. Project has an overdue task
        //
        // This allows the manually selected "At Risk" status
        // from the Projects page to appear on the Dashboard.
        // ========================================================

        var atRiskProjectIds = projects
            .Where(
                p =>
                    p.IsAtRisk)
            .Select(
                p =>
                    p.Id)
            .ToHashSet();

        var automaticallyAtRiskProjectIds = tasks
            .Where(
                t =>
                    t.Status == TaskStatus.Blocked ||
                    (
                        t.Status != TaskStatus.Done &&
                        t.Status != TaskStatus.Cancelled &&
                        t.PlannedEnd.HasValue &&
                        t.PlannedEnd.Value < now
                    ))
            .Select(
                t =>
                    t.ProjectId)
            .ToHashSet();

        // Combine manually marked risk with automatically detected risk.
        atRiskProjectIds.UnionWith(
            automaticallyAtRiskProjectIds);

        var atRiskProjects = projects.Count(
            p =>
                atRiskProjectIds.Contains(p.Id));

        // ========================================================
        // ON-TRACK PROJECTS
        // ========================================================
        //
        // Active projects that are not At Risk.
        // ========================================================

        var onTrackProjects = projects.Count(
            p =>
                p.Status == ProjectStatus.Active &&
                !p.IsArchived &&
                !atRiskProjectIds.Contains(p.Id));

        // ========================================================
        // PROJECT PERFORMANCE
        // ========================================================

        var projectPerformance = projects
            .Select(
                project =>
                {
                    var projectTasks = tasks
                        .Where(
                            t =>
                                t.ProjectId == project.Id)
                        .Where(
                            t =>
                                t.Status != TaskStatus.Cancelled)
                        .ToList();

                    var completionPercent =
                        projectTasks.Count > 0
                            ? (int)Math.Round(
                                projectTasks.Average(
                                    t =>
                                        t.Status == TaskStatus.Done
                                            ? 100m
                                            : Math.Clamp(
                                                t.CompletionPercent ?? 0,
                                                0,
                                                100)))
                            : 0;

                    var status =
                        atRiskProjectIds.Contains(project.Id)
                            ? "At Risk"
                            : project.Status ==
                              ProjectStatus.Completed
                                ? "Completed"
                                : project.Status ==
                                  ProjectStatus.Active
                                    ? "On Track"
                                    : project.Status.ToString();

                    return new DashboardProjectPerformanceResponse(
                        project.Id,
                        project.Name,
                        completionPercent,
                        status);
                })
            .OrderByDescending(
                p =>
                    p.CompletionPercent)
            .Take(4)
            .ToList();

        // ========================================================
        // UPCOMING DEADLINES
        // ========================================================

        var upcomingDeadlines = tasks
            .Where(
                t =>
                    t.Status != TaskStatus.Done &&
                    t.Status != TaskStatus.Cancelled &&
                    t.PlannedEnd.HasValue &&
                    t.PlannedEnd.Value >= now)
            .Join(
                projects,
                task =>
                    task.ProjectId,
                project =>
                    project.Id,
                (task, project) =>
                    new DashboardDeadlineResponse(
                        task.Id,
                        task.Title,
                        project.Id,
                        project.Name,
                        task.PlannedEnd!.Value))
            .OrderBy(
                d =>
                    d.DueDate)
            .Take(5)
            .ToList();

        // ========================================================
        // TASK ASSIGNMENTS
        // ========================================================

        var assignments = await _context.TaskAssignments
            .AsNoTracking()
            .Where(
                a =>
                    projectIds.Contains(
                        a.Task.ProjectId) &&
                    !a.Task.IsDeleted)
            .Select(
                a => new
                {
                    a.UserId,
                    a.TaskId,
                    EstimatedHours =
                        a.Task.EstimatedHours ?? 0m
                })
            .ToListAsync(cancellationToken);

        // ========================================================
        // PROJECT MEMBERS
        // ========================================================

        var memberIds = await _context.ProjectMembers
            .AsNoTracking()
            .Where(
                m =>
                    projectIds.Contains(m.ProjectId) &&
                    !m.IsBlocked &&
                    m.User.IsActive &&
                    !m.User.IsDeleted)
            .Select(
                m =>
                    m.UserId)
            .Distinct()
            .ToListAsync(cancellationToken);

        // ========================================================
        // PROJECT OWNERS
        // ========================================================

        var ownerIds = await accessibleProjects
            .Select(
                p =>
                    p.OwnerId)
            .Distinct()
            .ToListAsync(cancellationToken);

        var teamUserIds = memberIds
            .Concat(ownerIds)
            .Distinct()
            .ToList();

        // ========================================================
        // TEAM USERS
        // ========================================================

        var users = await _context.Users
            .AsNoTracking()
            .Where(
                u =>
                    teamUserIds.Contains(u.Id) &&
                    u.IsActive &&
                    !u.IsDeleted)
            .Select(
                u => new
                {
                    u.Id,
                    u.FullName,
                    u.AvatarUrl
                })
            .ToListAsync(cancellationToken);

        // ========================================================
        // TEAM WORKLOAD
        // ========================================================

        var teamWorkload = users
            .Select(
                member =>
                {
                    var memberAssignments = assignments
                        .Where(
                            a =>
                                a.UserId == member.Id)
                        .GroupBy(
                            a =>
                                a.TaskId)
                        .Select(
                            g =>
                                g.First())
                        .ToList();

                    var plannedHours =
                        memberAssignments.Sum(
                            a =>
                                a.EstimatedHours);

                    var workloadPercent =
                        Math.Round(
                            (plannedHours / 40m) * 100m,
                            2);

                    string workloadStatus;

                    if (
                        workloadPercent > 100m ||
                        plannedHours > 45m ||
                        (
                            memberAssignments.Count >= 8 &&
                            workloadPercent >= 80m
                        ))
                    {
                        workloadStatus = "Overloaded";
                    }
                    else if (
                        workloadPercent < 40m &&
                        memberAssignments.Count <= 1)
                    {
                        workloadStatus = "Underutilized";
                    }
                    else
                    {
                        workloadStatus = "Normal";
                    }

                    return new DashboardTeamWorkloadResponse(
                        member.Id,
                        member.FullName,
                        member.AvatarUrl,
                        workloadPercent,
                        workloadStatus);
                })
            .OrderByDescending(
                x =>
                    x.WorkloadPercent)
            .Take(10)
            .ToList();

        // ========================================================
        // FINAL DASHBOARD RESPONSE
        // ========================================================

        return new DashboardOverviewResponse(
            ActiveProjects: activeProjects,
            TasksDue: tasksDue,
            OverdueTasks: overdueTasks,
            AtRiskProjects: atRiskProjects,
            CompletedTasks: completedTasks,
            TotalTasks: totalTasks,
            OverallProgress: overallProgress,
            OnTrackProjects: onTrackProjects,
            ProjectPerformance: projectPerformance,
            UpcomingDeadlines: upcomingDeadlines,
            TeamWorkload: teamWorkload);
    }
}