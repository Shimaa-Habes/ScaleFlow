using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.Models;

namespace ScaleFlow.Models;

public class ScaleFlowDbContext : IdentityDbContext<User, Role, int>
{
    public ScaleFlowDbContext(
        DbContextOptions<ScaleFlowDbContext> options
    ) : base(options)
    {
    }

    public DbSet<Organization> Organizations => Set<Organization>();
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

    // Project Architecture
    public DbSet<ProjectArchitecture> ProjectArchitectures =>
        Set<ProjectArchitecture>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.ApplyConfigurationsFromAssembly(
            typeof(ScaleFlowDbContext).Assembly
        );

        // ============================================================
        // Project Tasks
        // ============================================================

        builder.Entity<ProjectTask>()
            .HasOne(x => x.ParentTask)
            .WithMany(x => x.SubTasks)
            .HasForeignKey(x => x.ParentTaskId);

        // ============================================================
        // Task Dependencies
        // ============================================================

        builder.Entity<TaskDependency>()
            .HasOne(x => x.Task)
            .WithMany(x => x.Dependencies)
            .HasForeignKey(x => x.TaskId);

        builder.Entity<TaskDependency>()
            .HasOne(x => x.DependsOnTask)
            .WithMany(x => x.DependentOn)
            .HasForeignKey(x => x.DependsOnTaskId);

        // ============================================================
        // Task Assignment
        // ============================================================

        builder.Entity<TaskAssignment>()
            .HasOne(x => x.User)
            .WithMany(x => x.TaskAssignments)
            .HasForeignKey(x => x.UserId);

        builder.Entity<TaskAssignment>()
            .HasOne(x => x.AssignedByUser)
            .WithMany(x => x.AssignedTasksBy)
            .HasForeignKey(x => x.AssignedBy);

        // ============================================================
        // Task Comments
        // ============================================================

        builder.Entity<TaskComment>()
            .HasOne(x => x.Author)
            .WithMany(x => x.Comments)
            .HasForeignKey(x => x.AuthorId);

        builder.Entity<TaskComment>()
            .HasOne(x => x.ParentComment)
            .WithMany(x => x.Replies)
            .HasForeignKey(x => x.ParentCommentId);

        // ============================================================
        // Task Attachments
        // ============================================================

        builder.Entity<TaskAttachment>()
            .HasOne(x => x.Uploader)
            .WithMany(x => x.Attachments)
            .HasForeignKey(x => x.UploaderId);

        // ============================================================
        // Notifications
        // ============================================================

        builder.Entity<Notification>()
            .HasOne(x => x.RecipientUser)
            .WithMany(x => x.Notifications)
            .HasForeignKey(x => x.RecipientUserId);

        builder.Entity<Notification>()
            .HasOne(x => x.ActorUser)
            .WithMany(x => x.NotificationsBy)
            .HasForeignKey(x => x.ActorUserId);

        // ============================================================
        // Generated Reports
        // ============================================================

        builder.Entity<GeneratedReport>()
            .HasOne(x => x.CreatedByUser)
            .WithMany(x => x.GeneratedReports)
            .HasForeignKey(x => x.CreatedBy);

        // ============================================================
        // Project fields
        // ============================================================

        builder.Entity<Project>()
            .Property(x => x.Name)
            .HasMaxLength(200);

        builder.Entity<Project>()
            .Property(x => x.Description)
            .HasMaxLength(4000);

        // ============================================================
        // Task fields
        // ============================================================

        builder.Entity<ProjectTask>()
            .Property(x => x.Title)
            .HasMaxLength(200);

        builder.Entity<ProjectTask>()
            .Property(x => x.Description)
            .HasMaxLength(4000);

        // ============================================================
        // Global query filters
        // ============================================================

        builder.Entity<Project>()
            .HasQueryFilter(x => !x.IsDeleted);

        builder.Entity<ProjectTask>()
            .HasQueryFilter(x =>
                !x.IsDeleted &&
                !x.Project.IsDeleted);

        builder.Entity<AiRun>()
            .HasQueryFilter(x =>
                !x.Project.IsDeleted);

        builder.Entity<AiPrediction>()
            .HasQueryFilter(x =>
                !x.AiRun.Project.IsDeleted);

        builder.Entity<AiRecommendation>()
            .HasQueryFilter(x =>
                !x.AiPrediction.AiRun.Project.IsDeleted);

        builder.Entity<Board>()
            .HasQueryFilter(x =>
                !x.Project.IsDeleted);

        builder.Entity<BoardColumn>()
            .HasQueryFilter(x =>
                !x.Board.Project.IsDeleted);

        builder.Entity<GeneratedReport>()
            .HasQueryFilter(x =>
                !x.Project.IsDeleted);

        builder.Entity<Milestone>()
            .HasQueryFilter(x =>
                !x.Project.IsDeleted);

        builder.Entity<ProjectHealthSnapshot>()
            .HasQueryFilter(x =>
                !x.Project.IsDeleted);

        builder.Entity<ProjectMember>()
            .HasQueryFilter(x =>
                !x.Project.IsDeleted);

        builder.Entity<WorkloadSnapshot>()
            .HasQueryFilter(x =>
                !x.Project.IsDeleted);

        builder.Entity<TaskAssignment>()
            .HasQueryFilter(x =>
                !x.Task.IsDeleted &&
                !x.Task.Project.IsDeleted);

        builder.Entity<TaskAttachment>()
            .HasQueryFilter(x =>
                !x.Task.IsDeleted &&
                !x.Task.Project.IsDeleted);

        builder.Entity<TaskComment>()
            .HasQueryFilter(x =>
                !x.Task.IsDeleted &&
                !x.Task.Project.IsDeleted);

        builder.Entity<TaskDependency>()
            .HasQueryFilter(x =>
                !x.Task!.IsDeleted &&
                !x.Task.Project.IsDeleted &&
                !x.DependsOnTask!.IsDeleted &&
                !x.DependsOnTask.Project.IsDeleted);

        builder.Entity<TaskStatusHistory>()
            .HasQueryFilter(x =>
                !x.Task.IsDeleted &&
                !x.Task.Project.IsDeleted);

        // Project Architecture belongs to a project,
        // so it follows the same soft-delete behavior.
        builder.Entity<ProjectArchitecture>()
            .HasQueryFilter(x =>
                !x.Project.IsDeleted);

        // ============================================================
        // Project constraints
        // ============================================================

        builder.Entity<Project>()
            .ToTable("Projects", table =>
            {
                table.HasCheckConstraint(
                    "CK_Projects_Budget",
                    "[Budget] IS NULL OR [Budget] >= 0"
                );

                table.HasCheckConstraint(
                    "CK_Projects_Dates",
                    "[StartDate] IS NULL OR [EndDate] IS NULL OR [EndDate] >= [StartDate]"
                );
            });

        // ============================================================
        // Project Task constraints
        // ============================================================

        builder.Entity<ProjectTask>()
            .ToTable("ProjectTasks", table =>
            {
                table.HasCheckConstraint(
                    "CK_ProjectTasks_Completion",
                    "[CompletionPercent] IS NULL OR [CompletionPercent] BETWEEN 0 AND 100"
                );

                table.HasCheckConstraint(
                    "CK_ProjectTasks_Hours",
                    "[EstimatedHours] IS NULL OR [EstimatedHours] >= 0"
                );

                table.HasCheckConstraint(
                    "CK_ProjectTasks_Dates",
                    "[PlannedStart] IS NULL OR [PlannedEnd] IS NULL OR [PlannedEnd] >= [PlannedStart]"
                );
            });

        // ============================================================
        // Unique indexes
        // ============================================================

        builder.Entity<ProjectMember>()
            .HasIndex(x => new { x.ProjectId, x.UserId })
            .IsUnique();

        builder.Entity<TeamMember>()
            .HasIndex(x => new { x.TeamId, x.UserId })
            .IsUnique();

        // ============================================================
        // Preserve audit records and avoid SQL Server
        // multiple cascade paths.
        // ============================================================

        foreach (var entity in builder.Model.GetEntityTypes())
        {
            foreach (var foreignKey in entity.GetForeignKeys())
            {
                foreignKey.DeleteBehavior = DeleteBehavior.Restrict;
            }

            foreach (var property in entity.GetProperties())
            {
                if (
                    property.ClrType == typeof(decimal) ||
                    property.ClrType == typeof(decimal?)
                )
                {
                    property.SetPrecision(18);
                    property.SetScale(4);
                }
            }
        }

        // ============================================================
        // Provider-specific soft-delete filter
        // ============================================================

        var providerName = Database.ProviderName ?? string.Empty;
        var isNpgsql = providerName.Contains("Npgsql");

        var softDeleteFilter = isNpgsql
            ? "\"IsDeleted\" = false"
            : "[IsDeleted] = 0";

        // ============================================================
        // User unique index
        // ============================================================

        builder.Entity<User>()
            .HasIndex(x => new { x.OrganizationId, x.Email })
            .IsUnique()
            .HasFilter(softDeleteFilter);

        // ============================================================
        // Organization unique index
        // ============================================================

        builder.Entity<Organization>()
            .HasIndex(x => x.Code)
            .IsUnique()
            .HasFilter(softDeleteFilter);

        // ============================================================
        // Role unique index
        // ============================================================

        builder.Entity<Role>()
            .HasIndex(x => x.Code)
            .IsUnique()
            .HasFilter(softDeleteFilter);

        // ============================================================
        // Task Assignment unique index
        // ============================================================

        builder.Entity<TaskAssignment>()
            .HasIndex(x => new { x.TaskId, x.UserId })
            .IsUnique();

        // ============================================================
        // Project Task - Created By
        // ============================================================

        builder.Entity<ProjectTask>()
            .HasOne(x => x.CreatedByUser)
            .WithMany(x => x.CreatedTasks)
            .HasForeignKey(x => x.CreatedBy)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Project - Owner
        // ============================================================

        builder.Entity<Project>()
            .HasOne(x => x.Owner)
            .WithMany(x => x.OwnedProjects)
            .HasForeignKey(x => x.OwnerId)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Project Task - Updated By
        // ============================================================

        builder.Entity<ProjectTask>()
            .HasOne(x => x.UpdatedByUser)
            .WithMany(x => x.UpdatedTasks)
            .HasForeignKey(x => x.UpdatedBy)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Task Status History
        // ============================================================

        builder.Entity<TaskStatusHistory>()
            .HasOne(x => x.ChangedByUser)
            .WithMany(x => x.TaskStatusChanges)
            .HasForeignKey(x => x.ChangedBy)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Notification - Recipient
        // ============================================================

        builder.Entity<Notification>()
            .HasOne(x => x.RecipientUser)
            .WithMany(x => x.Notifications)
            .HasForeignKey(x => x.RecipientUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Notification - Actor
        // ============================================================

        builder.Entity<Notification>()
            .HasOne(x => x.ActorUser)
            .WithMany(x => x.NotificationsBy)
            .HasForeignKey(x => x.ActorUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Task Dependency - Task
        // ============================================================

        builder.Entity<TaskDependency>()
            .HasOne(x => x.Task)
            .WithMany(x => x.Dependencies)
            .HasForeignKey(x => x.TaskId)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Task Dependency - Depends On Task
        // ============================================================

        builder.Entity<TaskDependency>()
            .HasOne(x => x.DependsOnTask)
            .WithMany(x => x.DependentOn)
            .HasForeignKey(x => x.DependsOnTaskId)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Task Assignment - Task
        // ============================================================

        builder.Entity<TaskAssignment>()
            .HasOne(x => x.Task)
            .WithMany(x => x.Assignments)
            .HasForeignKey(x => x.TaskId)
            .OnDelete(DeleteBehavior.Cascade);

        // ============================================================
        // Task Assignment - User
        // ============================================================

        builder.Entity<TaskAssignment>()
            .HasOne(x => x.User)
            .WithMany(x => x.TaskAssignments)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Project Member - User
        // ============================================================

        builder.Entity<ProjectMember>()
            .HasOne(x => x.User)
            .WithMany(x => x.ProjectMemberships)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Workload Snapshot - User
        // ============================================================

        builder.Entity<WorkloadSnapshot>()
            .HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Team Member - User
        // ============================================================

        builder.Entity<TeamMember>()
            .HasOne(x => x.User)
            .WithMany(x => x.TeamMemberships)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Task Attachment - Uploader
        // ============================================================

        builder.Entity<TaskAttachment>()
            .HasOne(x => x.Uploader)
            .WithMany(x => x.Attachments)
            .HasForeignKey(x => x.UploaderId)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Task Comment - Author
        // ============================================================

        builder.Entity<TaskComment>()
            .HasOne(x => x.Author)
            .WithMany(x => x.Comments)
            .HasForeignKey(x => x.AuthorId)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Task Assignment - Assigned By
        // ============================================================

        builder.Entity<TaskAssignment>()
            .HasOne(x => x.AssignedByUser)
            .WithMany(x => x.AssignedTasksBy)
            .HasForeignKey(x => x.AssignedBy)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // User Role - User
        // ============================================================

        builder.Entity<UserRole>()
            .HasOne(x => x.User)
            .WithMany(x => x.UserRoles)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // ============================================================
        // User Role - Role
        // ============================================================

        builder.Entity<UserRole>()
            .HasOne(x => x.Role)
            .WithMany(x => x.UserRoles)
            .HasForeignKey(x => x.RoleId)
            .OnDelete(DeleteBehavior.Cascade);

        // ============================================================
        // User Role - Assigned By
        // ============================================================

        builder.Entity<UserRole>()
            .HasOne(x => x.AssignedByUser)
            .WithMany()
            .HasForeignKey(x => x.AssignedBy)
            .OnDelete(DeleteBehavior.Restrict);

        // ============================================================
        // Project Architecture
        // ============================================================

        builder.Entity<ProjectArchitecture>(entity =>
        {
            entity.HasKey(x => x.Id);

            entity.HasOne(x => x.Project)
                .WithOne(x => x.Architecture)
                .HasForeignKey<ProjectArchitecture>(x => x.ProjectId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(x => x.ProjectId)
                .IsUnique();
        });
    }
}

