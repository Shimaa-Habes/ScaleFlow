using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.DTOs;
using ScaleFlow.Hubs;
using ScaleFlow.Middleware;
using ScaleFlow.Models;
using TaskStatus = ScaleFlow.Models.TaskStatus;

namespace ScaleFlow.Services;

public class ReportService : IReportService
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };

    private readonly ScaleFlowDbContext _context;
    private readonly IProjectService _projectService;
    private readonly IProjectProgressService _progressService;
    private readonly IHubContext<ScaleFlowHub> _hubContext;

    public ReportService(
        ScaleFlowDbContext context,
        IProjectService projectService,
        IProjectProgressService progressService,
        IHubContext<ScaleFlowHub> hubContext)
    {
        _context = context;
        _projectService = projectService;
        _progressService = progressService;
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

    public async Task<GeneratedReportResponse> GenerateReport(
        ClaimsPrincipal user, int projectId, GenerateReportRequest request, CancellationToken ct)
    {
        var userId = GetUserId(user);
        var project = await _projectService.GetProject(user, projectId, ct);
        var progress = await _progressService.GetProgress(user, projectId, ct);

        var tasks = await _context.ProjectTasks
            .AsNoTracking()
            .Where(t => t.ProjectId == projectId && !t.IsDeleted)
            .ToListAsync(ct);

        var now = DateTimeOffset.UtcNow;
        var overdueTasks = tasks.Where(t => t.Status != TaskStatus.Done && t.PlannedEnd.HasValue && t.PlannedEnd.Value < now).ToList();
        var blockedTasks = tasks.Where(t => t.Status == TaskStatus.Blocked).ToList();
        var highPriorityPending = tasks.Where(t => t.Priority == TaskPriority.High && t.Status != TaskStatus.Done).ToList();

        // Summary Data
        var summaryData = new ProjectSummaryReportData(
            project.Id,
            project.Name,
            project.Status.ToString(),
            project.Priority.ToString(),
            project.Budget,
            project.StartDate,
            project.EndDate,
            progress.TotalTasks,
            progress.CompletedTasks,
            progress.InProgressTasks,
            progress.BlockedTasks,
            progress.CancelledTasks,
            progress.ProgressPercent);

        // Performance Data
        var memberCount = await _context.ProjectMembers.CountAsync(m => m.ProjectId == projectId && !m.IsBlocked, ct) + 1; // +1 for owner
        var teamCount = await _context.Teams.CountAsync(t => t.ProjectId == projectId, ct);

        var assignments = await _context.TaskAssignments
            .AsNoTracking()
            .Where(a => a.Task.ProjectId == projectId && !a.Task.IsDeleted)
            .Include(a => a.User)
            .Include(a => a.Task)
            .ToListAsync(ct);

        var memberPerformances = assignments
            .GroupBy(a => a.UserId)
            .Select(g => new MemberPerformanceData(
                g.Key,
                g.First().User.FullName,
                g.Select(a => a.Task).DistinctBy(t => t.Id).Count(t => t.Status == TaskStatus.Done),
                g.Select(a => a.Task).DistinctBy(t => t.Id).Count(t => t.Status == TaskStatus.InProgress),
                g.Select(a => a.Task).DistinctBy(t => t.Id).Sum(t => t.ActualHours ?? 0)))
            .ToList();

        var totalEstimatedHours = tasks.Sum(t => t.EstimatedHours ?? 0);
        var totalActualHours = tasks.Sum(t => t.ActualHours ?? 0);

        var performanceData = new TeamPerformanceReportData(
            memberCount,
            teamCount,
            totalEstimatedHours,
            totalActualHours,
            memberPerformances);

        // Risk Data
        var riskFactors = new List<string>();
        if (overdueTasks.Count > 0)
        {
            riskFactors.Add($"There are {overdueTasks.Count} overdue tasks requiring attention.");
        }
        if (blockedTasks.Count > 0)
        {
            riskFactors.Add($"There are {blockedTasks.Count} blocked tasks hindering sprint progress.");
        }
        if (progress.ProgressPercent < 50m && project.EndDate.HasValue && (project.EndDate.Value - now).TotalDays < 14)
        {
            riskFactors.Add("Project deadline is within 14 days with completion under 50%.");
        }
        if (totalActualHours > totalEstimatedHours && totalEstimatedHours > 0)
        {
            riskFactors.Add($"Actual hours spent ({totalActualHours}h) exceeds estimated hours ({totalEstimatedHours}h).");
        }

        var riskData = new ProjectRiskReportData(
            overdueTasks.Count,
            blockedTasks.Count,
            highPriorityPending.Count,
            riskFactors);

        // AI Recommendations & Executive Summary
        var aiRecommendations = new List<string>();
        if (blockedTasks.Count > 0)
        {
            aiRecommendations.Add($"Focus immediate team efforts on resolving {blockedTasks.Count} blocked dependencies.");
        }
        if (overdueTasks.Count > 0)
        {
            aiRecommendations.Add($"Reschedule or reallocate resources for {overdueTasks.Count} overdue tasks.");
        }
        if (highPriorityPending.Count > 2)
        {
            aiRecommendations.Add($"Prioritize {highPriorityPending.Count} critical tasks in the next sprint planning.");
        }
        if (aiRecommendations.Count == 0)
        {
            aiRecommendations.Add("Project is progressing smoothly within planned parameters. Maintain current pace.");
        }

        var executiveSummary = $"Project '{project.Name}' overall progress is at {progress.ProgressPercent}%. " +
            $"Total tasks: {progress.TotalTasks} (Completed: {progress.CompletedTasks}, In Progress: {progress.InProgressTasks}, Blocked: {progress.BlockedTasks}). " +
            $"Identified {riskFactors.Count} key risk factors and {aiRecommendations.Count} AI recommendations.";

        var fullAiReport = new FullAiProjectReportData(
            summaryData,
            performanceData,
            riskData,
            aiRecommendations,
            executiveSummary);

        string reportJson = request.ReportType.ToLowerInvariant() switch
        {
            "summary" => JsonSerializer.Serialize(summaryData, JsonOptions),
            "performance" => JsonSerializer.Serialize(performanceData, JsonOptions),
            "risk" => JsonSerializer.Serialize(riskData, JsonOptions),
            _ => JsonSerializer.Serialize(fullAiReport, JsonOptions)
        };

        var generatedReport = new GeneratedReport
        {
            ProjectId = projectId,
            Title = request.Title.Trim(),
            PeriodFrom = request.PeriodFrom,
            PeriodTo = request.PeriodTo,
            SummaryText = executiveSummary,
            ReportJson = reportJson,
            CreatedBy = userId,
            CreatedAt = DateTimeOffset.UtcNow
        };

        _context.GeneratedReports.Add(generatedReport);
        await _context.SaveChangesAsync(ct);

        var creatorName = await _context.Users
            .Where(u => u.Id == userId)
            .Select(u => u.FullName)
            .SingleOrDefaultAsync(ct);

        var response = new GeneratedReportResponse(
            generatedReport.Id,
            generatedReport.ProjectId,
            generatedReport.Title,
            generatedReport.SummaryText,
            generatedReport.ReportJson,
            generatedReport.PeriodFrom,
            generatedReport.PeriodTo,
            generatedReport.CreatedBy,
            creatorName,
            generatedReport.CreatedAt);

        // Real-time broadcast to project room
        await _hubContext.Clients.Group($"project_{projectId}")
            .SendAsync("ReportGenerated", response, ct);

        return response;
    }

    public async Task<IReadOnlyList<GeneratedReportResponse>> ListReports(
        ClaimsPrincipal user, int projectId, int page, int pageSize, CancellationToken ct)
    {
        await _projectService.GetProject(user, projectId, ct);

        return await _context.GeneratedReports
            .AsNoTracking()
            .Where(r => r.ProjectId == projectId)
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => new GeneratedReportResponse(
                r.Id,
                r.ProjectId,
                r.Title,
                r.SummaryText,
                r.ReportJson,
                r.PeriodFrom,
                r.PeriodTo,
                r.CreatedBy,
                r.CreatedByUser != null ? r.CreatedByUser.FullName : null,
                r.CreatedAt))
            .ToListAsync(ct);
    }

    public async Task<GeneratedReportResponse> GetReport(
        ClaimsPrincipal user, int projectId, int id, CancellationToken ct)
    {
        await _projectService.GetProject(user, projectId, ct);

        return await _context.GeneratedReports
            .AsNoTracking()
            .Where(r => r.Id == id && r.ProjectId == projectId)
            .Select(r => new GeneratedReportResponse(
                r.Id,
                r.ProjectId,
                r.Title,
                r.SummaryText,
                r.ReportJson,
                r.PeriodFrom,
                r.PeriodTo,
                r.CreatedBy,
                r.CreatedByUser != null ? r.CreatedByUser.FullName : null,
                r.CreatedAt))
            .SingleOrDefaultAsync(ct)
            ?? throw new ApiException(404, "Report not found.");
    }
}
