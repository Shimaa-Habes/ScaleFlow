using System;

namespace ScaleFlow.Models;
public class TaskAssignment
{
    public int Id { get; set; }
    public int TaskId { get; set; }
    public int UserId { get; set; }
    public int AssignedBy { get; set; }
    public DateTimeOffset AssignedAt { get; set; } = DateTimeOffset.UtcNow;
    public bool IsPrimary { get; set; } = false;
    public ProjectTask Task { get; set; } = null!;
    public User User { get; set; } = null!;
    public User AssignedByUser { get; set; } = null!;
}



