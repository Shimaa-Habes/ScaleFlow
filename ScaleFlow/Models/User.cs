using System;
using System.Collections.Generic;

namespace ScaleFlow.Models;
public class User : SoftDeletableEntity
{
    public int OrganizationId { get; set; }
    public string Email { get; set; } = null!;
    public string PasswordHash { get; set; } = null!;
    public string FullName { get; set; } = null!;
    public string? Phone { get; set; }
    public string? JobTitle { get; set; }
    public string? AvatarUrl { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset? EmailVerifiedAt { get; set; }
    public DateTimeOffset? LastLoginAt { get; set; }

    public Organization Organization { get; set; } = null!;

    public ICollection<UserRole> UserRoles { get; set; } = new HashSet<UserRole>();
    public ICollection<ProjectMember> ProjectMemberships { get; set; } = new HashSet<ProjectMember>();
    public ICollection<TeamMember> TeamMemberships { get; set; } = new HashSet<TeamMember>();
    public ICollection<Project> OwnedProjects { get; set; } = new HashSet<Project>();
    public ICollection<TaskAssignment> TaskAssignments { get; set; } = new HashSet<TaskAssignment>();
    public ICollection<TaskAssignment> AssignedTasksBy { get; set; } = new HashSet<TaskAssignment>();
    public ICollection<TaskComment> Comments { get; set; } = new HashSet<TaskComment>();
    public ICollection<TaskAttachment> Attachments { get; set; } = new HashSet<TaskAttachment>();
    public ICollection<ProjectTask> CreatedTasks { get; set; } = new HashSet<ProjectTask>();
    public ICollection<ProjectTask> UpdatedTasks { get; set; } = new HashSet<ProjectTask>();
    public ICollection<TaskStatusHistory> TaskStatusChanges { get; set; } = new HashSet<TaskStatusHistory>();
    public ICollection<AiRecommendation> RecommendedTo { get; set; } = new HashSet<AiRecommendation>();
    public ICollection<GeneratedReport> GeneratedReports { get; set; } = new HashSet<GeneratedReport>();
    public ICollection<Notification> Notifications { get; set; } = new HashSet<Notification>();
    public ICollection<Notification> NotificationsBy { get; set; } = new HashSet<Notification>();
    public ICollection<AuditLog> AuditLogs { get; set; } = new HashSet<AuditLog>();
    public ICollection<RefreshToken> RefreshTokens { get; set; } = new HashSet<RefreshToken>();

    /*
      For SQL Server/PostgreSQL with soft delete, apply filtered unique:
      unique index on (OrganizationId, Email) where IsDeleted = 0.
    */
}



