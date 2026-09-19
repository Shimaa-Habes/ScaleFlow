using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.Models;

namespace ScaleFlow.Models;

public class ScaleFlowDbContext : IdentityDbContext<User, Role, int>
{
    public ScaleFlowDbContext(DbContextOptions<ScaleFlowDbContext> options) : base(options)
    {
    }

    public DbSet<Organization> Organizations => Set<Organization>();
    public DbSet<Permission> Permissions => Set<Permission>();
    public DbSet<RolePermission> RolePermissions => Set<RolePermission>();
    public DbSet<Project> Projects => Set<Project>();
    public DbSet<Team> Teams => Set<Team>();
    public DbSet<TeamMember> TeamMembers => Set<TeamMember>();
    public DbSet<ProjectMember> ProjectMembers => Set<ProjectMember>();
    public DbSet<Board> Boards => Set<Board>();
    public DbSet<BoardColumn> BoardColumns => Set<BoardColumn>();
    public DbSet<Milestone> Milestones => Set<Milestone>();
    public DbSet<ProjectTask> ProjectTasks => Set<ProjectTask>();
    public DbSet<TaskDependency> TaskDependencies => Set<TaskDependency>();
    public DbSet<TaskAssignment> TaskAssignments => Set<TaskAssignment>();
    public DbSet<TaskComment> TaskComments => Set<TaskComment>();
    public DbSet<TaskAttachment> TaskAttachments => Set<TaskAttachment>();
    public DbSet<TaskStatusHistory> TaskStatusHistories => Set<TaskStatusHistory>();
    public DbSet<TaskProgressSnapshot> TaskProgressSnapshots => Set<TaskProgressSnapshot>();
    public DbSet<AiRun> AiRuns => Set<AiRun>();
    public DbSet<AiPrediction> AiPredictions => Set<AiPrediction>();
    public DbSet<AiRecommendation> AiRecommendations => Set<AiRecommendation>();
    public DbSet<ProjectHealthSnapshot> ProjectHealthSnapshots => Set<ProjectHealthSnapshot>();
    public DbSet<WorkloadSnapshot> WorkloadSnapshots => Set<WorkloadSnapshot>();
    public DbSet<ReportTemplate> ReportTemplates => Set<ReportTemplate>();
    public DbSet<GeneratedReport> GeneratedReports => Set<GeneratedReport>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.ApplyConfigurationsFromAssembly(typeof(ScaleFlowDbContext).Assembly);

        builder.Entity<AiPrediction>()
            .Property(x => x.RiskScore)
            .HasPrecision(5, 4);

        builder.Entity<AiPrediction>()
            .Property(x => x.DelayProbability)
            .HasPrecision(5, 4);

        builder.Entity<AiPrediction>()
            .Property(x => x.Confidence)
            .HasPrecision(5, 4);

        builder.Entity<Project>()
            .Property(x => x.Budget)
            .HasPrecision(19, 4);

        builder.Entity<ProjectHealthSnapshot>()
            .Property(x => x.HealthScore)
            .HasPrecision(5, 2);

        builder.Entity<ProjectHealthSnapshot>()
            .Property(x => x.Velocity)
            .HasPrecision(12, 2);

        builder.Entity<ProjectHealthSnapshot>()
            .Property(x => x.Throughput)
            .HasPrecision(12, 2);

        builder.Entity<ProjectHealthSnapshot>()
            .Property(x => x.OpenRiskRatio)
            .HasPrecision(5, 4);

        builder.Entity<ProjectHealthSnapshot>()
            .Property(x => x.TeamUtilizationAvg)
            .HasPrecision(5, 4);

        builder.Entity<ProjectMember>()
            .Property(x => x.HourlyRate)
            .HasPrecision(19, 4);

        builder.Entity<ProjectTask>()
            .Property(x => x.EstimatedHours)
            .HasPrecision(10, 2);

        builder.Entity<ProjectTask>()
            .Property(x => x.ActualHours)
            .HasPrecision(10, 2);

        builder.Entity<WorkloadSnapshot>()
            .Property(x => x.PlannedHours)
            .HasPrecision(10, 2);

        builder.Entity<WorkloadSnapshot>()
            .Property(x => x.ActualHours)
            .HasPrecision(10, 2);

        builder.Entity<WorkloadSnapshot>()
            .Property(x => x.UtilizationRatio)
            .HasPrecision(5, 4);

        builder.Entity<WorkloadSnapshot>()
            .Property(x => x.OverloadScore)
            .HasPrecision(8, 4);

        var providerName = Database.ProviderName ?? string.Empty;
        var isNpgsql = providerName.Contains("Npgsql");
        var softDeleteFilter = isNpgsql
            ? "\"IsDeleted\" = false"
            : "[IsDeleted] = 0";

        builder.Entity<User>()
            .HasIndex(x => new { x.OrganizationId, x.Email })
            .IsUnique()
            .HasFilter(softDeleteFilter);

        builder.Entity<Organization>()
            .HasIndex(x => x.Code)
            .IsUnique()
            .HasFilter(softDeleteFilter);

        builder.Entity<Role>()
            .HasIndex(x => x.Code)
            .IsUnique()
            .HasFilter(softDeleteFilter);

        builder.Entity<TaskAssignment>()
            .HasIndex(x => new { x.TaskId, x.UserId })
            .IsUnique();

        builder.Entity<ProjectTask>()
            .HasOne(x => x.CreatedByUser)
            .WithMany(x => x.CreatedTasks)
            .HasForeignKey(x => x.CreatedBy)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<Project>()
            .HasOne(x => x.Owner)
            .WithMany(x => x.OwnedProjects)
            .HasForeignKey(x => x.OwnerId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<ProjectTask>()
            .HasOne(x => x.UpdatedByUser)
            .WithMany(x => x.UpdatedTasks)
            .HasForeignKey(x => x.UpdatedBy)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<TaskStatusHistory>()
            .HasOne(x => x.ChangedByUser)
            .WithMany(x => x.TaskStatusChanges)
            .HasForeignKey(x => x.ChangedBy)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<Notification>()
            .HasOne(x => x.RecipientUser)
            .WithMany(x => x.Notifications)
            .HasForeignKey(x => x.RecipientUserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<Notification>()
            .HasOne(x => x.ActorUser)
            .WithMany(x => x.NotificationsBy)
            .HasForeignKey(x => x.ActorUserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<TaskDependency>()
            .HasOne(x => x.Task)
            .WithMany(x => x.Dependencies)
            .HasForeignKey(x => x.TaskId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<TaskDependency>()
            .HasOne(x => x.DependsOnTask)
            .WithMany(x => x.DependentOn)
            .HasForeignKey(x => x.DependsOnTaskId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<TaskAssignment>()
            .HasOne(x => x.Task)
            .WithMany(x => x.Assignments)
            .HasForeignKey(x => x.TaskId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<TaskAssignment>()
            .HasOne(x => x.User)
            .WithMany(x => x.TaskAssignments)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<ProjectMember>()
            .HasOne(x => x.User)
            .WithMany(x => x.ProjectMemberships)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<WorkloadSnapshot>()
            .HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<TeamMember>()
            .HasOne(x => x.User)
            .WithMany(x => x.TeamMemberships)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<TaskAttachment>()
            .HasOne(x => x.Uploader)
            .WithMany(x => x.Attachments)
            .HasForeignKey(x => x.UploaderId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<TaskComment>()
            .HasOne(x => x.Author)
            .WithMany(x => x.Comments)
            .HasForeignKey(x => x.AuthorId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<TaskAssignment>()
            .HasOne(x => x.AssignedByUser)
            .WithMany(x => x.AssignedTasksBy)
            .HasForeignKey(x => x.AssignedBy)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<UserRole>()
            .HasOne(x => x.User)
            .WithMany(x => x.UserRoles)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<UserRole>()
            .HasOne(x => x.Role)
            .WithMany(x => x.UserRoles)
            .HasForeignKey(x => x.RoleId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<UserRole>()
            .HasOne(x => x.AssignedByUser)
            .WithMany()
            .HasForeignKey(x => x.AssignedBy)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

