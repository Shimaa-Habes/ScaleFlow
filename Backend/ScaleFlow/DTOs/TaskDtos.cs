using ScaleFlow.Models;
using TaskStatus = ScaleFlow.Models.TaskStatus;

namespace ScaleFlow.DTOs;

public class TaskRequest
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public TaskStatus Status { get; set; } = TaskStatus.Backlog;
    public TaskPriority Priority { get; set; } = TaskPriority.Medium;
    public TaskType Type { get; set; } = TaskType.Task;
    public DateTimeOffset? PlannedStart { get; set; }
    public DateTimeOffset? PlannedEnd { get; set; }
    public decimal? EstimatedHours { get; set; }
    public int? CompletionPercent { get; set; }
}

public record TaskResponse(int Id, int ProjectId, string Title, string? Description, TaskStatus Status,
    TaskPriority Priority, TaskType Type, DateTimeOffset? PlannedStart, DateTimeOffset? PlannedEnd,
    decimal? EstimatedHours, int? CompletionPercent, int CreatedBy, int UpdatedBy,
    DateTimeOffset CreatedAt, DateTimeOffset? UpdatedAt);
