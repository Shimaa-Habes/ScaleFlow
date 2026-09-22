namespace ScaleFlow.DTOs;

public record NotificationResponse(
    int Id,
    int RecipientUserId,
    int? ActorUserId,
    string? ActorName,
    string Type,
    string Title,
    string Message,
    string TargetType,
    int TargetId,
    int? ProjectId,
    DateTimeOffset? ReadAt,
    DateTimeOffset CreatedAt
);

public record NotificationSummaryResponse(
    int UnreadCount,
    int TotalCount
);
