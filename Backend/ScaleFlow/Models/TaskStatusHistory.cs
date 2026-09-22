using System;

namespace ScaleFlow.Models;
public class TaskStatusHistory
{
    public int Id { get; set; }
    public int TaskId { get; set; }
    public TaskStatus FromStatus { get; set; }
    public TaskStatus ToStatus { get; set; }
    public int ChangedBy { get; set; }
    public DateTimeOffset ChangedAt { get; set; } = DateTimeOffset.UtcNow;
    public string? Comment { get; set; }
    public ProjectTask Task { get; set; } = null!;
    public User ChangedByUser { get; set; } = null!;
}



