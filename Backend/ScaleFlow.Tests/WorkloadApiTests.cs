using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ScaleFlow.DTOs;
using ScaleFlow.Models;
using ScaleFlow.Services;
using Xunit;
using TaskStatus = ScaleFlow.Models.TaskStatus;

namespace ScaleFlow.Tests;

public partial class ManagementApiTests
{
    [Fact]
    public async Task Workload_ReturnsSummaryAndMemberUtilization_CalculatesStatusAccurately()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client(1);
        var projectId = await CreateProgressProject(client);

        // Add User 2 to project
        await client.PostAsJsonAsync($"/api/projects/{projectId}/members", new AddProjectMemberRequest { UserId = 2 });

        // Create tasks
        var path = $"/api/projects/{projectId}/tasks";
        var task1 = await CreatedId(await client.PostAsJsonAsync(path, new TaskRequest
        {
            Title = "Heavy Task",
            EstimatedHours = 50,
            Status = TaskStatus.InProgress
        }));

        var task2 = await CreatedId(await client.PostAsJsonAsync(path, new TaskRequest
        {
            Title = "Light Task",
            EstimatedHours = 5,
            Status = TaskStatus.InProgress
        }));

        // Assign Heavy Task to User 1
        await client.PostAsJsonAsync(
            $"/api/projects/{projectId}/workload/tasks/{task1}/assignments",
            new AssignTaskRequest(1, true));

        // Assign Light Task to User 2
        await client.PostAsJsonAsync(
            $"/api/projects/{projectId}/workload/tasks/{task2}/assignments",
            new AssignTaskRequest(2, true));

        // Act
        var response = await client.GetAsync($"/api/projects/{projectId}/workload");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var data = await ResponseData(response);

        Assert.Equal(2, data.GetProperty("totalMembers").GetInt32());
        Assert.Equal(2, data.GetProperty("totalAssignedTasks").GetInt32());

        var members = data.GetProperty("members");
        Assert.Equal(2, members.GetArrayLength());

        var user1Data = members.EnumerateArray().First(m => m.GetProperty("userId").GetInt32() == 1);
        Assert.Equal("Overloaded", user1Data.GetProperty("workloadStatus").GetString());
        Assert.Equal(50, user1Data.GetProperty("totalEstimatedHours").GetDecimal());

        var user2Data = members.EnumerateArray().First(m => m.GetProperty("userId").GetInt32() == 2);
        Assert.Equal("Underutilized", user2Data.GetProperty("workloadStatus").GetString());
        Assert.Equal(5, user2Data.GetProperty("totalEstimatedHours").GetDecimal());
    }

    [Fact]
    public async Task Workload_AssignAndUnassignTask_HandlesDuplicatesAndRemoval()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client(1);
        var projectId = await CreateProgressProject(client);

        var task = await CreatedId(await client.PostAsJsonAsync(
            $"/api/projects/{projectId}/tasks", new TaskRequest { Title = "Task to assign" }));

        var assignmentPath = $"/api/projects/{projectId}/workload/tasks/{task}/assignments";

        // Act 1: Assign to User 1
        var assignResponse = await client.PostAsJsonAsync(assignmentPath, new AssignTaskRequest(1, true));
        Assert.Equal(HttpStatusCode.OK, assignResponse.StatusCode);

        // Act 2: Assigning again to User 1 should return 409 Conflict
        var duplicateResponse = await client.PostAsJsonAsync(assignmentPath, new AssignTaskRequest(1, true));
        Assert.Equal(HttpStatusCode.Conflict, duplicateResponse.StatusCode);

        // Act 3: List assignments
        var listResponse = await client.GetAsync(assignmentPath);
        Assert.Equal(HttpStatusCode.OK, listResponse.StatusCode);
        var listData = await ResponseData(listResponse);
        Assert.Equal(1, listData.GetArrayLength());

        // Act 4: Remove assignment
        var deleteResponse = await client.DeleteAsync($"{assignmentPath}/1");
        Assert.Equal(HttpStatusCode.OK, deleteResponse.StatusCode);

        // Act 5: Verify list is empty
        var emptyList = await ResponseData(await client.GetAsync(assignmentPath));
        Assert.Equal(0, emptyList.GetArrayLength());
    }

    [Fact]
    public async Task Workload_AssignTaskToCrossOrganizationUser_ReturnsNotFound()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client(1);
        var projectId = await CreateProgressProject(client);

        var task = await CreatedId(await client.PostAsJsonAsync(
            $"/api/projects/{projectId}/tasks", new TaskRequest { Title = "Task" }));

        // Act: Assign to User 3 who belongs to Organization 2
        var response = await client.PostAsJsonAsync(
            $"/api/projects/{projectId}/workload/tasks/{task}/assignments",
            new AssignTaskRequest(3));

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
