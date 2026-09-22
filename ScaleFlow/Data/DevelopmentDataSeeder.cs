using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.Constants;
using ScaleFlow.Models;
using TaskStatus = ScaleFlow.Models.TaskStatus;

namespace ScaleFlow.Data;

public static class DevelopmentDataSeeder
{
    public static async Task SeedAsync(IServiceProvider services, IConfiguration configuration)
    {
        if (!configuration.GetValue<bool>("SeedData:Enabled")) return;

        var password = configuration["SeedData:Password"];
        if (string.IsNullOrWhiteSpace(password))
        {
            throw new InvalidOperationException("SeedData:Password is required when development seeding is enabled.");
        }

        var context = services.GetRequiredService<ScaleFlowDbContext>();
        var userManager = services.GetRequiredService<UserManager<User>>();

        var organization = await context.Organizations
            .IgnoreQueryFilters()
            .SingleOrDefaultAsync(x => x.Code == "DEMO");

        if (organization is null)
        {
            organization = new Organization
            {
                Name = "ScaleFlow Demo",
                Slug = "scaleflow-demo",
                Code = "DEMO",
                Industry = "Software",
                Timezone = "Asia/Jerusalem"
            };
            context.Organizations.Add(organization);
            await context.SaveChangesAsync();
        }

        var manager = await EnsureUser(userManager, organization.Id, "manager@scaleflow.local",
            "Demo Project Manager", "Project Manager", RoleConstants.ProjectManager, password);
        var leader = await EnsureUser(userManager, organization.Id, "leader@scaleflow.local",
            "Demo Team Leader", "Team Leader", RoleConstants.TeamLeader, password);
        var member = await EnsureUser(userManager, organization.Id, "member@scaleflow.local",
            "Demo Team Member", "Backend Developer", RoleConstants.TeamMember, password);

        var project = await context.Projects
            .IgnoreQueryFilters()
            .SingleOrDefaultAsync(x => x.OrganizationId == organization.Id && x.Name == "ScaleFlow Demo Project");

        if (project is null)
        {
            project = new Project
            {
                OrganizationId = organization.Id,
                OwnerId = manager.Id,
                Name = "ScaleFlow Demo Project",
                Description = "Development data for testing the ScaleFlow API.",
                Status = ProjectStatus.Active,
                Priority = ProjectPriority.High,
                StartDate = DateTimeOffset.UtcNow.Date,
                EndDate = DateTimeOffset.UtcNow.Date.AddMonths(3)
            };
            context.Projects.Add(project);
            await context.SaveChangesAsync();
        }

        await EnsureProjectMember(context, project.Id, leader.Id, "Team Leader");
        await EnsureProjectMember(context, project.Id, member.Id, "Developer");

        var team = await context.Teams.SingleOrDefaultAsync(x =>
            x.ProjectId == project.Id && x.Name == "Demo Delivery Team");

        if (team is null)
        {
            team = new Team
            {
                OrganizationId = organization.Id,
                ProjectId = project.Id,
                Name = "Demo Delivery Team",
                Description = "Team used for development endpoint testing.",
                LeadUserId = leader.Id
            };
            context.Teams.Add(team);
            await context.SaveChangesAsync();
        }

        await EnsureTeamMember(context, team.Id, leader.Id, "Lead");
        await EnsureTeamMember(context, team.Id, member.Id, "Backend Developer");

        var contractTask = await EnsureTask(context, project.Id, manager.Id, "Design API contract",
            TaskStatus.Done, 100, TaskPriority.High);
        var dependencyTask = await EnsureTask(context, project.Id, manager.Id, "Implement dependency API",
            TaskStatus.InProgress, 60, TaskPriority.High);
        var flutterTask = await EnsureTask(context, project.Id, manager.Id, "Connect Flutter client",
            TaskStatus.Todo, 0, TaskPriority.Medium);

        await EnsureDependency(context, dependencyTask.Id, contractTask.Id);
        await EnsureDependency(context, flutterTask.Id, dependencyTask.Id);
    }

    private static async Task<User> EnsureUser(UserManager<User> userManager, int organizationId,
        string email, string fullName, string jobTitle, string role, string password)
    {
        var user = await userManager.FindByEmailAsync(email);
        if (user is null)
        {
            user = new User
            {
                OrganizationId = organizationId,
                UserName = email,
                Email = email,
                EmailConfirmed = true,
                FullName = fullName,
                JobTitle = jobTitle,
                IsActive = true
            };

            var result = await userManager.CreateAsync(user, password);
            if (!result.Succeeded)
            {
                throw new InvalidOperationException(string.Join("; ", result.Errors.Select(x => x.Description)));
            }
        }

        if (!await userManager.IsInRoleAsync(user, role))
        {
            var result = await userManager.AddToRoleAsync(user, role);
            if (!result.Succeeded)
            {
                throw new InvalidOperationException(string.Join("; ", result.Errors.Select(x => x.Description)));
            }
        }

        return user;
    }

    private static async Task EnsureProjectMember(ScaleFlowDbContext context, int projectId, int userId, string role)
    {
        if (await context.ProjectMembers.AnyAsync(x => x.ProjectId == projectId && x.UserId == userId)) return;
        context.ProjectMembers.Add(new ProjectMember { ProjectId = projectId, UserId = userId, RoleOverride = role });
        await context.SaveChangesAsync();
    }

    private static async Task EnsureTeamMember(ScaleFlowDbContext context, int teamId, int userId, string role)
    {
        if (await context.TeamMembers.AnyAsync(x => x.TeamId == teamId && x.UserId == userId)) return;
        context.TeamMembers.Add(new TeamMember { TeamId = teamId, UserId = userId, RoleInTeam = role });
        await context.SaveChangesAsync();
    }

    private static async Task<ProjectTask> EnsureTask(ScaleFlowDbContext context, int projectId, int actorId,
        string title, TaskStatus status, int completion, TaskPriority priority)
    {
        var task = await context.ProjectTasks.SingleOrDefaultAsync(x => x.ProjectId == projectId && x.Title == title);
        if (task is not null) return task;

        task = new ProjectTask
        {
            ProjectId = projectId,
            Title = title,
            Description = "Seeded development task.",
            Status = status,
            Priority = priority,
            Type = TaskType.Task,
            CompletionPercent = completion,
            EstimatedHours = 8,
            CreatedBy = actorId,
            UpdatedBy = actorId
        };
        context.ProjectTasks.Add(task);
        await context.SaveChangesAsync();
        return task;
    }

    private static async Task EnsureDependency(ScaleFlowDbContext context, int taskId, int dependsOnTaskId)
    {
        if (await context.TaskDependencies.AnyAsync(x =>
            x.TaskId == taskId && x.DependsOnTaskId == dependsOnTaskId)) return;

        context.TaskDependencies.Add(new TaskDependency
        {
            TaskId = taskId,
            DependsOnTaskId = dependsOnTaskId,
            DependencyType = DependencyType.FinishToStart,
            Notes = "Seeded development dependency."
        });
        await context.SaveChangesAsync();
    }
}
