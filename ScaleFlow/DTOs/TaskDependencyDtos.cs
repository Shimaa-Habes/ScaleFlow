using ScaleFlow.Models;

namespace ScaleFlow.DTOs;

public class TaskDependencyRequest
{
    public int DependsOnTaskId { get; set; }
    public DependencyType DependencyType { get; set; } = DependencyType.FinishToStart;
    public int? LagDays { get; set; }
    public string? Notes { get; set; }
}

public record TaskDependencyResponse(int Id, int TaskId, int DependsOnTaskId,
    DependencyType DependencyType, int? LagDays, string? Notes, DateTimeOffset CreatedAt);
