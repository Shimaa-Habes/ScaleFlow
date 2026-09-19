using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ScaleFlow.DTOs;
using ScaleFlow.Models;
using ScaleFlow.Services;
using ScaleFlow.Validation;
using Xunit;
using TaskStatus = ScaleFlow.Models.TaskStatus;

namespace ScaleFlow.Tests;

public partial class ManagementApiTests
{
    private static async Task<int> CreateProgressProject(HttpClient client) =>
        await CreatedId(await client.PostAsJsonAsync("/api/projects", new ProjectRequest { Name = "Project" }));

    private static async Task<JsonElement> ResponseData(HttpResponseMessage response)
    {
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.GetProperty("success").GetBoolean());
        return json.GetProperty("data");
    }

    // Verifies that cancelled and deleted tasks do not affect progress.
    [Fact]
    public async Task GetProgress_ReturnsAverageCompletion_WhenTasksExist()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ScaleFlowDbContext>();
        db.ProjectTasks.AddRange(
            new ProjectTask { ProjectId = project, Title = "Done", Status = TaskStatus.Done, CreatedBy = 1, UpdatedBy = 1 },
            new ProjectTask { ProjectId = project, Title = "Partial", CompletionPercent = 50, CreatedBy = 1, UpdatedBy = 1 },
            new ProjectTask { ProjectId = project, Title = "Cancelled", Status = TaskStatus.Cancelled, CreatedBy = 1, UpdatedBy = 1 },
            new ProjectTask { ProjectId = project, Title = "Deleted", IsDeleted = true, CreatedBy = 1, UpdatedBy = 1 });
        await db.SaveChangesAsync();

        // Act
        var data = await ResponseData(await client.GetAsync($"/api/projects/{project}/progress"));

        // Assert
        Assert.Equal(75m, data.GetProperty("progressPercent").GetDecimal());
        Assert.Equal(3, data.GetProperty("totalTasks").GetInt32());
        Assert.Equal(1, data.GetProperty("cancelledTasks").GetInt32());
    }

    // Verifies that an empty progress denominator returns zero.
    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task GetProgress_ReturnsZero_WhenNoActiveTasksExist(bool cancelled)
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);
        if (cancelled)
        {
            await CreatedId(await client.PostAsJsonAsync($"/api/projects/{project}/tasks",
                new TaskRequest { Title = "Cancelled", Status = TaskStatus.Cancelled }));
        }

        // Act
        var data = await ResponseData(await client.GetAsync($"/api/projects/{project}/progress"));

        // Assert
        Assert.Equal(0m, data.GetProperty("progressPercent").GetDecimal());
    }

    // Verifies basic project membership creation, reading, updating, and removal.
    [Fact]
    public async Task ProjectMembers_ReturnDisplayData_WhenOwnerManagesMembership()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);
        var path = $"/api/projects/{project}/members";

        // Act
        await CreatedId(await client.PostAsJsonAsync(path, new AddProjectMemberRequest { UserId = 2 }));
        var member = await ResponseData(await client.GetAsync($"{path}/2"));
        var updated = await ResponseData(await client.PutAsJsonAsync($"{path}/2",
            new UpdateProjectMemberRequest { RoleOverride = "Reviewer" }));
        var removed = await client.DeleteAsync($"{path}/2");

        // Assert
        Assert.Equal("Member", member.GetProperty("fullName").GetString());
        Assert.Equal("Reviewer", updated.GetProperty("roleOverride").GetString());
        Assert.Equal(HttpStatusCode.OK, removed.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"{path}/2")).StatusCode);
    }

    // Verifies basic team and team-member operations.
    [Fact]
    public async Task Teams_ReturnMemberCounts_WhenOwnerManagesTeam()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);
        await CreatedId(await client.PostAsJsonAsync($"/api/projects/{project}/members", new AddProjectMemberRequest { UserId = 2 }));
        var path = $"/api/projects/{project}/teams";
        var team = await CreatedId(await client.PostAsJsonAsync(path, new TeamRequest { Name = "Backend", LeadUserId = 2 }));

        // Act
        await CreatedId(await client.PostAsJsonAsync($"{path}/{team}/members", new AddTeamMemberRequest { UserId = 2 }));
        var data = await ResponseData(await client.GetAsync($"{path}/{team}"));
        var updated = await ResponseData(await client.PutAsJsonAsync($"{path}/{team}/members/2",
            new UpdateTeamMemberRequest { RoleInTeam = "Reviewer" }));
        var removed = await client.DeleteAsync($"{path}/{team}/members/2");
        var deleted = await client.DeleteAsync($"{path}/{team}");

        // Assert
        Assert.Equal(1, data.GetProperty("memberCount").GetInt32());
        Assert.Equal("Member", data.GetProperty("leadName").GetString());
        Assert.Equal("Reviewer", updated.GetProperty("roleInTeam").GetString());
        Assert.Equal(HttpStatusCode.OK, removed.StatusCode);
        Assert.Equal(HttpStatusCode.OK, deleted.StatusCode);
    }

    // Verifies that revoking project access also removes team links.
    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task ProjectMembers_RemoveTeamLinks_WhenBlockedOrRemoved(bool block)
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);
        var path = $"/api/projects/{project}";
        await CreatedId(await client.PostAsJsonAsync($"{path}/members", new AddProjectMemberRequest { UserId = 2 }));
        var team = await CreatedId(await client.PostAsJsonAsync($"{path}/teams", new TeamRequest { Name = "Team", LeadUserId = 2 }));
        await CreatedId(await client.PostAsJsonAsync($"{path}/teams/{team}/members", new AddTeamMemberRequest { UserId = 2 }));

        // Act
        var response = block
            ? await client.PutAsJsonAsync($"{path}/members/2", new UpdateProjectMemberRequest { IsBlocked = true })
            : await client.DeleteAsync($"{path}/members/2");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var data = await ResponseData(await client.GetAsync($"{path}/teams/{team}"));
        Assert.Equal(0, data.GetProperty("memberCount").GetInt32());
        Assert.Equal(JsonValueKind.Null, data.GetProperty("leadUserId").ValueKind);
    }

    // Verifies that invalid participants cannot become project members.
    [Theory]
    [InlineData(1, HttpStatusCode.BadRequest)]
    [InlineData(3, HttpStatusCode.NotFound)]
    [InlineData(999, HttpStatusCode.NotFound)]
    public async Task AddProjectMember_ReturnsError_WhenUserIsIneligible(int userId, HttpStatusCode expected)
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);

        // Act
        var response = await client.PostAsJsonAsync($"/api/projects/{project}/members",
            new AddProjectMemberRequest { UserId = userId });

        // Assert
        Assert.Equal(expected, response.StatusCode);
    }

    // Verifies that repeated membership requests conflict.
    [Fact]
    public async Task AddProjectMember_ReturnsConflict_WhenMembershipExists()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);
        var path = $"/api/projects/{project}/members";
        await CreatedId(await client.PostAsJsonAsync(path, new AddProjectMemberRequest { UserId = 2 }));

        // Act
        var response = await client.PostAsJsonAsync(path, new AddProjectMemberRequest { UserId = 2 });

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    // Verifies that team membership does not grant project access.
    [Fact]
    public async Task AddTeamMember_ReturnsNotFound_WhenUserIsNotProjectMember()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);
        var team = await CreatedId(await client.PostAsJsonAsync($"/api/projects/{project}/teams", new TeamRequest { Name = "Team" }));

        // Act
        var response = await client.PostAsJsonAsync($"/api/projects/{project}/teams/{team}/members",
            new AddTeamMemberRequest { UserId = 2 });

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // Verifies that project members cannot perform owner-only management.
    [Theory]
    [InlineData("members")]
    [InlineData("teams")]
    public async Task ProjectManagement_ReturnsForbidden_WhenActorIsMember(string route)
    {
        // Arrange
        using var factory = new Factory();
        using var owner = await factory.Client();
        using var member = await factory.Client(2);
        var project = await CreateProgressProject(owner);
        await CreatedId(await owner.PostAsJsonAsync($"/api/projects/{project}/members", new AddProjectMemberRequest { UserId = 2 }));

        // Act
        var response = route == "members"
            ? await member.PostAsJsonAsync($"/api/projects/{project}/members", new AddProjectMemberRequest { UserId = 2 })
            : await member.PostAsJsonAsync($"/api/projects/{project}/teams", new TeamRequest { Name = "Team" });

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // Verifies that a team cannot be read through another project's route.
    [Fact]
    public async Task GetTeam_ReturnsNotFound_WhenProjectDoesNotMatch()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);
        var other = await CreateProgressProject(client);
        var team = await CreatedId(await client.PostAsJsonAsync($"/api/projects/{project}/teams", new TeamRequest { Name = "Team" }));

        // Act
        var response = await client.GetAsync($"/api/projects/{other}/teams/{team}");

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // Verifies required team names using the validator directly.
    [Fact]
    public void ValidateTeam_ReturnsInvalid_WhenNameIsEmpty()
    {
        // Arrange
        var validator = new TeamRequestValidator();
        var request = new TeamRequest();

        // Act
        var result = validator.Validate(request);

        // Assert
        Assert.Contains(result.Errors, error => error.PropertyName == nameof(TeamRequest.Name));
    }

    // Verifies membership identifiers using the validator directly.
    [Fact]
    public void ValidateProjectMember_ReturnsInvalid_WhenUserIdIsZero()
    {
        // Arrange
        var validator = new AddProjectMemberRequestValidator();
        var request = new AddProjectMemberRequest();

        // Act
        var result = validator.Validate(request);

        // Assert
        Assert.Contains(result.Errors, error => error.PropertyName == nameof(AddProjectMemberRequest.UserId));
    }
}
