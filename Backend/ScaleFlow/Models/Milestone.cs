using System;
using System.Collections.Generic;

namespace ScaleFlow.Models;
public class Milestone
{
    public int Id { get; set; }
    public int ProjectId { get; set; }
    public string Title { get; set; } = null!;
    public DateTimeOffset? TargetDate { get; set; }
    public MilestoneStatus Status { get; set; } = MilestoneStatus.Planned;
    public int OrderIndex { get; set; } = 0;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }
    public Project Project { get; set; } = null!;
    public ICollection<ProjectTask> Tasks { get; set; } = new HashSet<ProjectTask>();
}



