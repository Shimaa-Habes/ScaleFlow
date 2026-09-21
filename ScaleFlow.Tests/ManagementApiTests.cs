using System.Net;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using ScaleFlow;
using ScaleFlow.DTOs;
using ScaleFlow.Models;
using ScaleFlow.Middleware;
using ScaleFlow.Services;
using Xunit;

namespace ScaleFlow.Tests;

public partial class ManagementApiTests
{
    [Theory]
    [InlineData(null, true)]
    [InlineData("invalid", true)]
    [InlineData("0", true)]
    [InlineData("-1", true)]
    [InlineData("1", false)]
    public async Task Service_RejectsMissingInvalidOrUnauthenticatedIdentity(string? userId, bool authenticated)
    {
        // Arrange
        using var db = new ScaleFlowDbContext(new DbContextOptionsBuilder<ScaleFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
        var projectService = new ProjectManagementService(db);
        var taskService = new TaskService(db);
        var claims = userId is null ? Array.Empty<Claim>() : new[] { new Claim(ClaimTypes.NameIdentifier, userId) };
        var user = new ClaimsPrincipal(new ClaimsIdentity(claims, authenticated ? "Test" : null));

        // Act
        var projectError = await Assert.ThrowsAsync<ApiException>(() => projectService.GetProject(user, 1, CancellationToken.None));
        var taskError = await Assert.ThrowsAsync<ApiException>(() => taskService.GetTask(user, 1, 1, CancellationToken.None));

        // Assert
        Assert.Equal(401, projectError.StatusCode);
        Assert.Equal(401, taskError.StatusCode);
    }

    private sealed class Factory : WebApplicationFactory<Program>
    {
        private readonly IMlService? _mlService;

        public Factory(IMlService? mlService = null)
        {
            _mlService = mlService;
        }

        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Testing");
            builder.ConfigureServices(services =>
            {
                var databaseName = Guid.NewGuid().ToString();
                services.RemoveAll<DbContextOptions<ScaleFlowDbContext>>();
                services.AddDbContext<ScaleFlowDbContext>(o => o.UseInMemoryDatabase(databaseName));
                if (_mlService is not null)
                {
                    services.RemoveAll<IMlService>();
                    services.AddSingleton<IMlService>(_mlService);
                }
            });
        }
        public async Task<HttpClient> Client(int userId = 1)
        {
            var client = CreateClient(new WebApplicationFactoryClientOptions { BaseAddress = new Uri("https://localhost") });
            using var scope = Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ScaleFlowDbContext>();
            if (!await db.Users.AnyAsync())
            {
                db.Organizations.AddRange(new Organization { Id = 1, Name = "Org", Slug = "org", Code = "ORG" },
                    new Organization { Id = 2, Name = "Other", Slug = "other", Code = "OTHER" });
                db.Users.AddRange(new User { Id = 1, OrganizationId = 1, FullName = "Owner" },
                    new User { Id = 2, OrganizationId = 1, FullName = "Member" },
                    new User { Id = 3, OrganizationId = 2, FullName = "Other user" });
                await db.SaveChangesAsync();
            }
            var user = await db.Users.FindAsync(userId);
            var token = scope.ServiceProvider.GetRequiredService<IJwtTokenService>().GenerateToken(user!, Array.Empty<string>());
            client.DefaultRequestHeaders.Authorization = new("Bearer", token);
            return client;
        }
    }

    private static async Task<int> CreatedId(HttpResponseMessage response)
    {
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        Assert.NotNull(response.Headers.Location);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.GetProperty("success").GetBoolean());
        return json.GetProperty("data").GetProperty("id").GetInt32();
    }

    [Fact]
    public async Task ProjectAndTaskCrud_RecordsHistoryAndSoftDeletes()
    {
        using var factory = new Factory();
        using var client = await factory.Client();
        var project = await CreatedId(await client.PostAsJsonAsync("/api/projects", new ProjectRequest { Name = "Project" }));
        var path = $"/api/projects/{project}/tasks";
        var task = await CreatedId(await client.PostAsJsonAsync(path, new TaskRequest { Title = "Task" }));
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync(path)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync($"{path}/{task}", new TaskRequest
            { Title = "Updated", Status = ScaleFlow.Models.TaskStatus.Done, CompletionPercent = 100 })).StatusCode);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<ScaleFlowDbContext>();
            Assert.Equal(1, await db.TaskStatusHistories.CountAsync());
            Assert.Equal(1, (await db.ProjectTasks.SingleAsync()).UpdatedBy);
        }
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync($"/api/projects/{project}", new ProjectRequest { Name = "Updated project" })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.DeleteAsync($"{path}/{task}")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"{path}/{task}")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.DeleteAsync($"/api/projects/{project}")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"/api/projects/{project}")).StatusCode);
        using var finalScope = factory.Services.CreateScope();
        var finalDb = finalScope.ServiceProvider.GetRequiredService<ScaleFlowDbContext>();
        Assert.True((await finalDb.ProjectTasks.IgnoreQueryFilters().SingleAsync()).IsDeleted);
        Assert.True((await finalDb.Projects.IgnoreQueryFilters().SingleAsync()).IsDeleted);
    }

    [Theory]
    [InlineData("{\"name\":\" \"}")]
    [InlineData("{\"name\":\"Test\",\"budget\":-1}")]
    [InlineData("{\"name\":\"Test\",\"status\":999}")]
    [InlineData("{\"name\":\"Test\",\"startDate\":\"2026-10-02T00:00:00Z\",\"endDate\":\"2026-10-01T00:00:00Z\"}")]
    [InlineData("{\"name\":")]
    [InlineData("null")]
    public async Task InvalidProject_ReturnsValidationEnvelope(string payload)
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        // Act
        var result = await client.PostAsync("/api/projects", new StringContent(payload, Encoding.UTF8, "application/json"));
        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, result.StatusCode);
        var json = await result.Content.ReadFromJsonAsync<JsonElement>();
        Assert.False(json.GetProperty("success").GetBoolean());
        Assert.NotEqual(JsonValueKind.Null, json.GetProperty("errors").ValueKind);
    }

    [Theory]
    [InlineData("{\"title\":\"\"}")]
    [InlineData("{\"title\":\"Task\",\"completionPercent\":101}")]
    [InlineData("{\"title\":\"Task\",\"estimatedHours\":-1}")]
    [InlineData("{\"title\":\"Task\",\"type\":999}")]
    [InlineData("{\"title\":\"Task\",\"plannedStart\":\"2026-10-02T00:00:00Z\",\"plannedEnd\":\"2026-10-01T00:00:00Z\"}")]
    public async Task InvalidTask_ReturnsBadRequest(string payload)
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        // Act
        var result = await client.PostAsync("/api/projects/1/tasks", new StringContent(payload, Encoding.UTF8, "application/json"));
        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, result.StatusCode);
    }

    [Fact]
    public async Task Access_IsScopedToOrganizationAndMembership()
    {
        using var factory = new Factory();
        using var owner = await factory.Client();
        var id = await CreatedId(await owner.PostAsJsonAsync("/api/projects", new ProjectRequest { Name = "Private" }));
        using var other = await factory.Client(3);
        Assert.Equal(HttpStatusCode.NotFound, (await other.GetAsync($"/api/projects/{id}")).StatusCode);
        using var member = await factory.Client(2);
        Assert.Equal(HttpStatusCode.NotFound, (await member.GetAsync($"/api/projects/{id}")).StatusCode);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<ScaleFlowDbContext>();
            db.ProjectMembers.Add(new ProjectMember { ProjectId = id, UserId = 2 });
            await db.SaveChangesAsync();
        }
        Assert.Equal(HttpStatusCode.OK, (await member.GetAsync($"/api/projects/{id}")).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await member.DeleteAsync($"/api/projects/{id}")).StatusCode);
        await CreatedId(await member.PostAsJsonAsync($"/api/projects/{id}/tasks", new TaskRequest { Title = "Member task" }));
        Assert.Equal(HttpStatusCode.NotFound, (await owner.GetAsync($"/api/projects/{id}/tasks/999")).StatusCode);
    }

    [Fact]
    public async Task AuthenticationPaginationAndRoutingErrors_UseEnvelope()
    {
        using var factory = new Factory();
        using var client = await factory.Client();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.GetAsync("/api/projects?page=0")).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.GetAsync("/api/projects?pageSize=101")).StatusCode);
        var missing = await client.GetAsync("/api/projects/0");
        Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode);
        Assert.False((await missing.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("success").GetBoolean());
        client.DefaultRequestHeaders.Authorization = null;
        var unauthorized = await client.GetAsync("/api/projects");
        Assert.Equal(HttpStatusCode.Unauthorized, unauthorized.StatusCode);
        Assert.False((await unauthorized.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("success").GetBoolean());
    }

    [Fact]
    public void SqlServerModel_HasNoShadowForeignKeys_AndHasMigration()
    {
        using var db = new ScaleFlowDbContext(new DbContextOptionsBuilder<ScaleFlowDbContext>()
            .UseSqlServer("Server=(localdb)\\MSSQLLocalDB;Database=ScaleFlowDb;Trusted_Connection=True;TrustServerCertificate=True").Options);
        Assert.NotEmpty(db.Database.GetMigrations());
        Assert.All(db.Model.GetEntityTypes().SelectMany(x => x.GetForeignKeys()).SelectMany(x => x.Properties),
            property => Assert.False(property.IsShadowProperty(), property.Name));
        Assert.Equal(200, db.Model.FindEntityType(typeof(Project))!.FindProperty("Name")!.GetMaxLength());
        // Keep standard Identity roles and the retained security models.
        Assert.DoesNotContain(db.Model.GetEntityTypes(), entity =>
            entity.ClrType.Name is "UserRole" or "Permission" or "RolePermission" or "TaskProgressSnapshot");
        Assert.NotNull(db.Model.FindEntityType(typeof(Microsoft.AspNetCore.Identity.IdentityUserRole<int>)));
        Assert.NotNull(db.Model.FindEntityType(typeof(AuditLog)));
        Assert.NotNull(db.Model.FindEntityType(typeof(RefreshToken)));
    }

    // Creates a small task pair for dependency tests.
    private static async Task<(string Path, int TaskId, int PrerequisiteId)> CreateDependencyTasks(HttpClient client)
    {
        var project = await CreateProgressProject(client);
        var path = $"/api/projects/{project}/tasks";
        var task = await CreatedId(await client.PostAsJsonAsync(path, new TaskRequest { Title = "Task" }));
        var prerequisite = await CreatedId(await client.PostAsJsonAsync(path, new TaskRequest { Title = "Prerequisite" }));
        return (path, task, prerequisite);
    }

    // Verifies basic dependency creation, reading, updating, and removal.
    [Fact]
    public async Task Dependencies_ReturnUpdatedDto_WhenOwnerManagesRelationship()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var tasks = await CreateDependencyTasks(client);
        var path = $"{tasks.Path}/{tasks.TaskId}/dependencies";

        // Act
        var id = await CreatedId(await client.PostAsJsonAsync(path,
            new TaskDependencyRequest { DependsOnTaskId = tasks.PrerequisiteId }));
        var data = await ResponseData(await client.GetAsync($"{path}/{id}"));
        var updated = await ResponseData(await client.PutAsJsonAsync($"{path}/{id}",
            new TaskDependencyRequest { DependsOnTaskId = tasks.PrerequisiteId, Notes = "Updated" }));
        var removed = await client.DeleteAsync($"{path}/{id}");

        // Assert
        Assert.Equal(tasks.PrerequisiteId, data.GetProperty("dependsOnTaskId").GetInt32());
        Assert.Equal("Updated", updated.GetProperty("notes").GetString());
        Assert.Equal(HttpStatusCode.OK, removed.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"{path}/{id}")).StatusCode);
    }

    // Verifies that a task cannot depend on itself.
    [Fact]
    public async Task AddDependency_ReturnsBadRequest_WhenTaskDependsOnItself()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var tasks = await CreateDependencyTasks(client);

        // Act
        var response = await client.PostAsJsonAsync($"{tasks.Path}/{tasks.TaskId}/dependencies",
            new TaskDependencyRequest { DependsOnTaskId = tasks.TaskId });

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // Verifies that the same relationship cannot be added twice.
    [Fact]
    public async Task AddDependency_ReturnsConflict_WhenRelationshipExists()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var tasks = await CreateDependencyTasks(client);
        var path = $"{tasks.Path}/{tasks.TaskId}/dependencies";
        var request = new TaskDependencyRequest { DependsOnTaskId = tasks.PrerequisiteId };
        await CreatedId(await client.PostAsJsonAsync(path, request));

        // Act
        var response = await client.PostAsJsonAsync(path, request);

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    // Verifies that following prerequisites cannot lead back to the starting task.
    [Fact]
    public async Task AddDependency_ReturnsBadRequest_WhenRelationshipCreatesIndirectCycle()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var tasks = await CreateDependencyTasks(client);
        var third = await CreatedId(await client.PostAsJsonAsync(tasks.Path, new TaskRequest { Title = "Third" }));
        await CreatedId(await client.PostAsJsonAsync($"{tasks.Path}/{tasks.TaskId}/dependencies",
            new TaskDependencyRequest { DependsOnTaskId = tasks.PrerequisiteId }));
        await CreatedId(await client.PostAsJsonAsync($"{tasks.Path}/{tasks.PrerequisiteId}/dependencies",
            new TaskDependencyRequest { DependsOnTaskId = third }));

        // Act
        var response = await client.PostAsJsonAsync($"{tasks.Path}/{third}/dependencies",
            new TaskDependencyRequest { DependsOnTaskId = tasks.TaskId });

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // Verifies that updates run the same cycle check as creation.
    [Fact]
    public async Task UpdateDependency_ReturnsBadRequest_WhenRelationshipCreatesCycle()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var tasks = await CreateDependencyTasks(client);
        var third = await CreatedId(await client.PostAsJsonAsync(tasks.Path, new TaskRequest { Title = "Third" }));
        await CreatedId(await client.PostAsJsonAsync($"{tasks.Path}/{tasks.TaskId}/dependencies",
            new TaskDependencyRequest { DependsOnTaskId = tasks.PrerequisiteId }));
        var path = $"{tasks.Path}/{tasks.PrerequisiteId}/dependencies";
        var id = await CreatedId(await client.PostAsJsonAsync(path, new TaskDependencyRequest { DependsOnTaskId = third }));

        // Act
        var response = await client.PutAsJsonAsync($"{path}/{id}",
            new TaskDependencyRequest { DependsOnTaskId = tasks.TaskId });

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // Verifies that a prerequisite must belong to the same project.
    [Fact]
    public async Task AddDependency_ReturnsNotFound_WhenPrerequisiteBelongsToAnotherProject()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var tasks = await CreateDependencyTasks(client);
        var other = await CreateProgressProject(client);
        var otherTask = await CreatedId(await client.PostAsJsonAsync($"/api/projects/{other}/tasks", new TaskRequest { Title = "Other" }));

        // Act
        var response = await client.PostAsJsonAsync($"{tasks.Path}/{tasks.TaskId}/dependencies",
            new TaskDependencyRequest { DependsOnTaskId = otherTask });

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // Verifies that inaccessible projects cannot receive new dependencies.
    [Theory]
    [InlineData(2)]
    [InlineData(3)]
    public async Task AddDependency_ReturnsNotFound_WhenActorCannotAccessProject(int userId)
    {
        // Arrange
        using var factory = new Factory();
        using var owner = await factory.Client();
        using var outsider = await factory.Client(userId);
        var tasks = await CreateDependencyTasks(owner);

        // Act
        var response = await outsider.PostAsJsonAsync($"{tasks.Path}/{tasks.TaskId}/dependencies",
            new TaskDependencyRequest { DependsOnTaskId = tasks.PrerequisiteId });

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // Verifies that invalid dependency fields return the API validation envelope.
    [Theory]
    [InlineData("{\"dependsOnTaskId\":0}")]
    [InlineData("{\"dependsOnTaskId\":1,\"dependencyType\":999}")]
    public async Task AddDependency_ReturnsBadRequest_WhenPayloadIsInvalid(string payload)
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var content = new StringContent(payload, Encoding.UTF8, "application/json");

        // Act
        var response = await client.PostAsync("/api/projects/1/tasks/1/dependencies", content);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var result = await response.Content.ReadFromJsonAsync<ApiResponse<object>>();
        Assert.NotNull(result);
        Assert.False(result.Success);
        Assert.NotNull(result.Errors);
    }
}
