namespace ScaleFlow.DTOs;

public record AssignTaskRequest(
    int AssigneeUserId,
    bool IsPrimary = false
);

public record TaskAssignmentResponse(
    int Id,
    int TaskId,
    int UserId,
    string UserName,
    int AssignedBy,
    bool IsPrimary,
    DateTimeOffset AssignedAt
);

public record MemberWorkloadResponse(
    int UserId,
    string FullName,
    string? AvatarUrl,
    string? JobTitle,
    int AssignedTasksCount,
    decimal TotalEstimatedHours,
    decimal TotalActualHours,
    int CompletedTasksCount,
    int InProgressTasksCount,
    int OverdueTasksCount,
    decimal UtilizationRatio,
    string WorkloadStatus
);

public record ProjectWorkloadSummaryResponse(
    int ProjectId,
    int TotalMembers,
    int TotalAssignedTasks,
    int UnassignedTasksCount,
    decimal AverageUtilization,
    int OverloadedMembersCount,
    int UnderutilizedMembersCount,
    IReadOnlyList<MemberWorkloadResponse> Members
);
