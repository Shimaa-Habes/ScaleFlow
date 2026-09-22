using ScaleFlow.Models;
using TaskStatus = ScaleFlow.Models.TaskStatus;

namespace ScaleFlow.DTOs;

public class AiAnalysisRequest
{
    public int InputWindowDays { get; set; } = 30;
}

// Backend-side input contract; the external ML wire format will be agreed at integration.
public record AiProjectInput(ProjectResponse Project, int InputWindowDays,
    IReadOnlyList<AiTaskInput> Tasks, IReadOnlyList<AiDependencyInput> Dependencies);

public record AiTaskInput(int Id, string Title, TaskStatus Status, TaskPriority Priority,
    DateTimeOffset? PlannedStart, DateTimeOffset? PlannedEnd, DateTimeOffset? ActualStart,
    DateTimeOffset? ActualEnd, decimal? EstimatedHours, decimal? ActualHours, int? CompletionPercent);

public record AiDependencyInput(int TaskId, int DependsOnTaskId, DependencyType DependencyType, int? LagDays);
