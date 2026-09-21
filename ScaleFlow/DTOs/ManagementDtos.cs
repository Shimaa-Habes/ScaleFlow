using ScaleFlow.Models;
using TaskStatus = ScaleFlow.Models.TaskStatus;

namespace ScaleFlow.DTOs;

public class ProjectRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public ProjectStatus Status { get; set; } = ProjectStatus.Planning;
    public ProjectPriority Priority { get; set; } = ProjectPriority.Medium;
    public decimal? Budget { get; set; }
    public DateTimeOffset? StartDate { get; set; }
    public DateTimeOffset? EndDate { get; set; }
}

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

public record ProjectResponse(int Id, int OrganizationId, int OwnerId, string Name, string? Description,
    ProjectStatus Status, ProjectPriority Priority, decimal? Budget, DateTimeOffset? StartDate,
    DateTimeOffset? EndDate, DateTimeOffset CreatedAt, DateTimeOffset? UpdatedAt);
public record TaskResponse(int Id, int ProjectId, string Title, string? Description, TaskStatus Status,
    TaskPriority Priority, TaskType Type, DateTimeOffset? PlannedStart, DateTimeOffset? PlannedEnd,
    decimal? EstimatedHours, int? CompletionPercent, int CreatedBy, int UpdatedBy,
    DateTimeOffset CreatedAt, DateTimeOffset? UpdatedAt);
