namespace ScaleFlow.DTOs;

public record DashboardOverviewResponse(
    int ActiveProjects,
    int TasksDue,
    int OverdueTasks,
    int AtRiskProjects,
    int CompletedTasks,
    int TotalTasks,
    decimal OverallProgress,
    int OnTrackProjects,
    IReadOnlyList<DashboardProjectPerformanceResponse> ProjectPerformance,
    IReadOnlyList<DashboardDeadlineResponse> UpcomingDeadlines,
    IReadOnlyList<DashboardTeamWorkloadResponse> TeamWorkload
);

public record DashboardProjectPerformanceResponse(
    int ProjectId,
    string ProjectName,
    int CompletionPercent,
    string Status
);

public record DashboardDeadlineResponse(
    int TaskId,
    string TaskTitle,
    int ProjectId,
    string ProjectName,
    DateTimeOffset DueDate
);

public record DashboardTeamWorkloadResponse(
    int UserId,
    string FullName,
    string? AvatarUrl,
    decimal WorkloadPercent,
    string WorkloadStatus
);