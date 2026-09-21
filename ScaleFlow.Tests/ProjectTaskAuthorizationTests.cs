using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.Constants;
using ScaleFlow.Controllers;
using ScaleFlow.DTOs;
using ScaleFlow.Models;
using Xunit;

namespace ScaleFlow.Tests;

public class ProjectTaskAuthorizationTests
{
    [Fact]
    public async Task ProjectMember_CanReadProjectAndTasks()
    {
        await using var db = CreateDatabase();
        var member = new User { Id = 2, OrganizationId = 1, UserName = "member", FullName = "Member", IsActive = true };
        var project = CreateProject(10, 1, 1);
        project.Members.Add(new ProjectMember { ProjectId = 10, UserId = 2 });
        db.Users.Add(member);
        db.Projects.Add(project);
        db.ProjectTasks.Add(new ProjectTask { Id = 20, ProjectId = 10, CreatedBy = 1, UpdatedBy = 1, Title = "Visible task" });
        await db.SaveChangesAsync();

        var principal = Principal(2, RoleConstants.TeamMember);
        var projectsController = new ProjectsController(db) { ControllerContext = Context(principal) };
        var tasksController = new TasksController(db) { ControllerContext = Context(principal) };

        Assert.IsType<OkObjectResult>(await projectsController.GetProject(10, CancellationToken.None));
        Assert.IsType<OkObjectResult>(await tasksController.GetTasks(10, CancellationToken.None));
    }

    [Fact]
    public async Task UnauthenticatedProjectAccess_Returns401()
    {
        await using var db = CreateDatabase();
        var controller = new ProjectsController(db) { ControllerContext = Context(new ClaimsPrincipal(new ClaimsIdentity())) };

        var result = await controller.GetProject(10, CancellationToken.None);

        Assert.IsType<UnauthorizedResult>(result);
    }

    [Fact]
    public async Task ClientUpdatingTask_Returns403()
    {
        await using var db = CreateDatabase();
        var client = new User { Id = 2, OrganizationId = 1, UserName = "client", FullName = "Client", IsActive = true };
        var project = CreateProject(10, 1, 1);
        project.Members.Add(new ProjectMember { ProjectId = 10, UserId = 2 });
        db.Users.Add(client);
        db.Projects.Add(project);
        db.ProjectTasks.Add(new ProjectTask { Id = 20, ProjectId = 10, CreatedBy = 1, UpdatedBy = 1, Title = "Client cannot edit" });
        await db.SaveChangesAsync();

        var controller = new TasksController(db) { ControllerContext = Context(Principal(2, RoleConstants.Client)) };
        var result = await controller.UpdateTask(10, 20, new UpdateTaskRequest { Title = "Changed" }, CancellationToken.None);

        Assert.IsType<ForbidResult>(result);
    }

    [Fact]
    public async Task CreateTask_WithNonMemberAssignee_Returns400WithoutCreatingTask()
    {
        await using var db = CreateDatabase();
        var manager = new User { Id = 1, OrganizationId = 1, UserName = "manager", FullName = "Manager", IsActive = true };
        var project = CreateProject(10, 1, 1);
        db.Users.Add(manager);
        db.Projects.Add(project);
        await db.SaveChangesAsync();

        var controller = new TasksController(db) { ControllerContext = Context(Principal(1, RoleConstants.ProjectManager)) };
        var result = await controller.CreateTask(10, new CreateTaskRequest
        {
            Title = "Should not persist",
            AssignedUserId = 99
        }, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.Empty(await db.ProjectTasks.ToListAsync());
    }

    [Fact]
    public async Task CrossOrganizationProjectAccess_Returns404()
    {
        await using var db = CreateDatabase();
        db.Users.Add(new User { Id = 2, OrganizationId = 2, UserName = "other-org", FullName = "Other Org", IsActive = true });
        db.Projects.Add(CreateProject(10, 1, 1));
        await db.SaveChangesAsync();

        var controller = new ProjectsController(db) { ControllerContext = Context(Principal(2, RoleConstants.Client)) };
        var result = await controller.GetProject(10, CancellationToken.None);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task NonMemberProjectAccess_ReturnsForbid_WhenAuthenticated()
    {
        await using var db = CreateDatabase();
        db.Users.Add(new User { Id = 2, OrganizationId = 1, UserName = "non-member", FullName = "Non Member", IsActive = true });
        db.Projects.Add(CreateProject(10, 1, 1));
        await db.SaveChangesAsync();

        var controller = new ProjectsController(db) { ControllerContext = Context(Principal(2, RoleConstants.TeamMember)) };
        var result = await controller.GetProject(10, CancellationToken.None);

        Assert.IsType<ForbidResult>(result);
    }

    [Fact]
    public async Task AssignTaskToUserFromDifferentOrganization_ReturnsBadRequest()
    {
        await using var db = CreateDatabase();
        var manager = new User { Id = 1, OrganizationId = 1, UserName = "manager", FullName = "Manager", IsActive = true };
        var externalUser = new User { Id = 99, OrganizationId = 2, UserName = "external", FullName = "External", IsActive = true };
        var project = CreateProject(10, 1, 1);
        project.Members.Add(new ProjectMember { ProjectId = 10, UserId = 99 });
        db.Users.Add(manager);
        db.Users.Add(externalUser);
        db.Projects.Add(project);
        await db.SaveChangesAsync();

        var controller = new TasksController(db) { ControllerContext = Context(Principal(1, RoleConstants.ProjectManager)) };
        var result = await controller.CreateTask(10, new CreateTaskRequest
        {
            Title = "Cross org assign",
            AssignedUserId = 99
        }, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.Empty(await db.TaskAssignments.ToListAsync());
    }

    [Fact]
    public void ProjectAndTaskEndpoints_DeclareJwtAndRoleAuthorization()
    {
        var projectType = typeof(ProjectsController);
        var taskType = typeof(TasksController);
        Assert.NotNull(projectType.GetCustomAttributes(typeof(AuthorizeAttribute), true).Single());
        Assert.NotNull(taskType.GetCustomAttributes(typeof(AuthorizeAttribute), true).Single());

        Assert.Equal(RoleConstants.ProjectManager, RoleOf(projectType, nameof(ProjectsController.CreateProject)));
        Assert.Equal(RoleConstants.ProjectManager, RoleOf(projectType, nameof(ProjectsController.UpdateProject)));
        Assert.Equal(RoleConstants.ProjectManager, RoleOf(projectType, nameof(ProjectsController.DeleteProject)));
        Assert.Equal(RoleConstants.ProjectManager + "," + RoleConstants.TeamLeader, RoleOf(taskType, nameof(TasksController.CreateTask)));
        Assert.Equal(RoleConstants.ProjectManager + "," + RoleConstants.TeamLeader + "," + RoleConstants.TeamMember,
            RoleOf(taskType, nameof(TasksController.UpdateTask)));
    }

    private static string? RoleOf(Type controllerType, string methodName)
    {
        return controllerType.GetMethod(methodName)!
            .GetCustomAttributes(typeof(AuthorizeAttribute), true)
            .Cast<AuthorizeAttribute>()
            .Single(attribute => attribute.Roles is not null)
            .Roles;
    }

    private static ScaleFlowDbContext CreateDatabase()
    {
        var options = new DbContextOptionsBuilder<ScaleFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new ScaleFlowDbContext(options);
    }

    private static Project CreateProject(int id, int organizationId, int ownerId)
    {
        return new Project
        {
            Id = id,
            OrganizationId = organizationId,
            OwnerId = ownerId,
            Name = "Project " + id
        };
    }

    private static ClaimsPrincipal Principal(int userId, string role)
    {
        var identity = new ClaimsIdentity(
            new[]
            {
                new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
                new Claim(ClaimTypes.Role, role)
            },
            "Bearer");
        return new ClaimsPrincipal(identity);
    }

    private static ControllerContext Context(ClaimsPrincipal principal)
    {
        return new ControllerContext { HttpContext = new DefaultHttpContext { User = principal } };
    }
}