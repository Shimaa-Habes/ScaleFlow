using System;

namespace ScaleFlow.Models;
public class TaskDependency
{
    public int Id { get; set; }
    public int TaskId { get; set; }
    public int DependsOnTaskId { get; set; }
    public DependencyType DependencyType { get; set; } = DependencyType.FinishToStart;
    public int? LagDays { get; set; }
    public string? Notes { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public ProjectTask? Task { get; set; }
    public ProjectTask? DependsOnTask { get; set; }
}



