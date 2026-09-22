using System;

namespace ScaleFlow.Models;
public class TaskProgressSnapshot
{
    public int Id { get; set; }
    public int TaskId { get; set; }
    public DateTimeOffset RecordedAt { get; set; } = DateTimeOffset.UtcNow;
    public int ProgressPercent { get; set; }
    public string? Notes { get; set; }
    public ProjectTask Task { get; set; } = null!;
}



