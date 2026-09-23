using System;
using System.Collections.Generic;

namespace ScaleFlow.Models;

public class Project : SoftDeletableEntity
{
    public int OrganizationId { get; set; }
    public int OwnerId { get; set; }

    public string Name { get; set; } = null!;
    public string? Description { get; set; }

    public string? WorkspaceUrl { get; set; }

    public int Progress { get; set; } = 0;

    public bool IsAtRisk { get; set; } = false;

    public string? ImageUrl { get; set; }

    public ProjectStatus Status { get; set; } = ProjectStatus.Planning;
    public ProjectPriority Priority { get; set; } = ProjectPriority.Medium;

    public decimal? Budget { get; set; }

    public DateTimeOffset? StartDate { get; set; }
    public DateTimeOffset? EndDate { get; set; }

    public bool IsArchived { get; set; } = false;

    public Organization Organization { get; set; } = null!;
    public User Owner { get; set; } = null!;

    public ICollection<ProjectMember> Members { get; set; }
        = new HashSet<ProjectMember>();

    public ICollection<Team> Teams { get; set; }
        = new HashSet<Team>();

    public ICollection<ProjectTask> Tasks { get; set; }
        = new HashSet<ProjectTask>();

    public ICollection<Board> Boards { get; set; }
        = new HashSet<Board>();

    public ICollection<Milestone> Milestones { get; set; }
        = new HashSet<Milestone>();

    public ICollection<AiRun> AiRuns { get; set; }
        = new HashSet<AiRun>();

    public ICollection<ProjectHealthSnapshot> HealthSnapshots { get; set; }
        = new HashSet<ProjectHealthSnapshot>();

    public ICollection<WorkloadSnapshot> WorkloadSnapshots { get; set; }
        = new HashSet<WorkloadSnapshot>();

    public ICollection<GeneratedReport> GeneratedReports { get; set; }
        = new HashSet<GeneratedReport>();

    public ICollection<Notification> Notifications { get; set; }
        = new HashSet<Notification>();

    public ProjectArchitecture? Architecture { get; set; }
}