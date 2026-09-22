namespace ScaleFlow.DTOs;

public record GenerateReportRequest(
    string Title,
    string ReportType = "FullAi",
    DateTimeOffset? PeriodFrom = null,
    DateTimeOffset? PeriodTo = null
);

public record GeneratedReportResponse(
    int Id,
    int ProjectId,
    string Title,
    string? SummaryText,
    string? ReportJson,
    DateTimeOffset? PeriodFrom,
    DateTimeOffset? PeriodTo,
    int? CreatedBy,
    string? CreatedByName,
    DateTimeOffset CreatedAt
);

public record ProjectSummaryReportData(
    int ProjectId,
    string ProjectName,
    string Status,
    string Priority,
    decimal? Budget,
    DateTimeOffset? StartDate,
    DateTimeOffset? EndDate,
    int TotalTasks,
    int CompletedTasks,
    int InProgressTasks,
    int BlockedTasks,
    int CancelledTasks,
    decimal ProgressPercent
);

public record MemberPerformanceData(
    int UserId,
    string FullName,
    int CompletedTasks,
    int InProgressTasks,
    decimal TotalActualHours
);

public record TeamPerformanceReportData(
    int TotalMembers,
    int TotalTeams,
    decimal TotalEstimatedHours,
    decimal TotalActualHours,
    IReadOnlyList<MemberPerformanceData> MemberPerformances
);

public record ProjectRiskReportData(
    int OverdueTasksCount,
    int BlockedTasksCount,
    int HighPriorityPendingTasksCount,
    IReadOnlyList<string> RiskFactors
);

public record FullAiProjectReportData(
    ProjectSummaryReportData Summary,
    TeamPerformanceReportData Performance,
    ProjectRiskReportData Risks,
    IReadOnlyList<string> AiRecommendations,
    string ExecutiveSummary
);
