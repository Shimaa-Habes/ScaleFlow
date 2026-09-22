using ScaleFlow.Models;

namespace ScaleFlow.DTOs;

public sealed class CreateProjectRequest
{
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public ProjectStatus Status { get; set; } = ProjectStatus.Planning;
    public ProjectPriority Priority { get; set; } = ProjectPriority.Medium;
    public decimal? Budget { get; set; }
    public DateTimeOffset? StartDate { get; set; }
    public DateTimeOffset? EndDate { get; set; }
}

public sealed class UpdateProjectRequest
{
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public ProjectStatus Status { get; set; }
    public ProjectPriority Priority { get; set; }
    public decimal? Budget { get; set; }
    public DateTimeOffset? StartDate { get; set; }
    public DateTimeOffset? EndDate { get; set; }
    public bool IsArchived { get; set; }
}

public sealed class CreateTaskRequest
{
    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public ScaleFlow.Models.TaskStatus Status { get; set; } = ScaleFlow.Models.TaskStatus.Backlog;
    public TaskPriority Priority { get; set; } = TaskPriority.Medium;
    public TaskType Type { get; set; } = TaskType.Task;
    public int? AssignedUserId { get; set; }
    public DateTimeOffset? PlannedStart { get; set; }
    public DateTimeOffset? PlannedEnd { get; set; }
    public decimal? EstimatedHours { get; set; }
}

public sealed class UpdateTaskRequest
{
    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public ScaleFlow.Models.TaskStatus Status { get; set; }
    public TaskPriority Priority { get; set; }
    public TaskType Type { get; set; }
    public DateTimeOffset? PlannedStart { get; set; }
    public DateTimeOffset? PlannedEnd { get; set; }
    public decimal? EstimatedHours { get; set; }
    public int? CompletionPercent { get; set; }
}