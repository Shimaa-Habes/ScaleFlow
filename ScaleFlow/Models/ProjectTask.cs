using System;
using System.Collections.Generic;

namespace ScaleFlow.Models;
public class ProjectTask : SoftDeletableEntity
{
    public int ProjectId { get; set; }
    public int? MilestoneId { get; set; }
    public int? BoardColumnId { get; set; }
    public int? ParentTaskId { get; set; }
    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public TaskStatus Status { get; set; } = TaskStatus.Backlog;
    public TaskPriority Priority { get; set; } = TaskPriority.Medium;
    public TaskType Type { get; set; } = TaskType.Task;
    public DateTimeOffset? PlannedStart { get; set; }
    public DateTimeOffset? PlannedEnd { get; set; }
    public DateTimeOffset? ActualStart { get; set; }
    public DateTimeOffset? ActualEnd { get; set; }
    public decimal? EstimatedHours { get; set; }
    public decimal? ActualHours { get; set; }
    public int? CompletionPercent { get; set; }
    public int? RiskLevel { get; set; }
    public int CreatedBy { get; set; }
    public int UpdatedBy { get; set; }
    public Project Project { get; set; } = null!;
    public Milestone? Milestone { get; set; }
    public BoardColumn? BoardColumn { get; set; }
    public ProjectTask? ParentTask { get; set; }
    public User CreatedByUser { get; set; } = null!;
    public User UpdatedByUser { get; set; } = null!;
    public ICollection<ProjectTask> SubTasks { get; set; } = new HashSet<ProjectTask>();
    public ICollection<TaskDependency> Dependencies { get; set; } = new HashSet<TaskDependency>();
    public ICollection<TaskDependency> DependentOn { get; set; } = new HashSet<TaskDependency>();
    public ICollection<TaskAssignment> Assignments { get; set; } = new HashSet<TaskAssignment>();
    public ICollection<TaskComment> Comments { get; set; } = new HashSet<TaskComment>();
    public ICollection<TaskAttachment> Attachments { get; set; } = new HashSet<TaskAttachment>();
    public ICollection<TaskStatusHistory> StatusHistory { get; set; } = new HashSet<TaskStatusHistory>();
    public ICollection<TaskProgressSnapshot> ProgressSnapshots { get; set; } = new HashSet<TaskProgressSnapshot>();
}



