namespace ScaleFlow.DTOs;

public record ProjectProgressResponse(int ProjectId, int TotalTasks, int CompletedTasks,
    int InProgressTasks, int BlockedTasks, int CancelledTasks, decimal ProgressPercent);
