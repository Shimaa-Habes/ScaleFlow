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
    }
}

