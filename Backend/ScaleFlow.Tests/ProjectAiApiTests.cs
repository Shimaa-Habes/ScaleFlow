using System.Net;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ScaleFlow.DTOs;
using ScaleFlow.Models;
using ScaleFlow.Services;
using Xunit;

namespace ScaleFlow.Tests;

public partial class ManagementApiTests
{
    // Fixed test data is never registered in the production application.
    private sealed class TestMlService : IMlService
    {
        public AiProjectInput? LastInput { get; private set; }
        public string? LastOperation { get; private set; }
        public int Calls { get; private set; }

        private void Capture(AiProjectInput input, string operation, CancellationToken ct)
        {
            ct.ThrowIfCancellationRequested();
            LastInput = input;
            LastOperation = operation;
            Calls++;
        }

        public Task<DelayPredictionResponse> PredictDelay(AiProjectInput request, CancellationToken ct)
        {
            Capture(request, "delay-prediction", ct);
            return Task.FromResult(new DelayPredictionResponse(request.Project.Id, 0.7m, 3, 0.8m, "Delay explanation"));
        }

        public Task<RiskAnalysisResponse> AnalyzeRisk(AiProjectInput request, CancellationToken ct)
        {
            Capture(request, "risk-analysis", ct);
            return Task.FromResult(new RiskAnalysisResponse(request.Project.Id, 0.6m, 0.8m, "Risk explanation"));
        }

        public Task<BottleneckDetectionResponse> DetectBottlenecks(AiProjectInput request, CancellationToken ct)
        {
            Capture(request, "bottleneck-detection", ct);
            IReadOnlyList<BottleneckTaskResponse> items = request.Tasks
                .Take(1).Select(task => new BottleneckTaskResponse(task.Id, 0.9m, "Bottleneck explanation")).ToArray();
            return Task.FromResult(new BottleneckDetectionResponse(request.Project.Id, items));
        }

        public Task<AiProjectHealthResponse> GetProjectHealth(AiProjectInput request, CancellationToken ct)
        {
            Capture(request, "project-health", ct);
            return Task.FromResult(new AiProjectHealthResponse(request.Project.Id, 75m, 2, 1, 0.8m, "Health explanation"));
        }
    }


    // Verifies that each endpoint reports the disconnected ML service.
    [Theory]
    [InlineData("delay-prediction")]
    [InlineData("risk-analysis")]
    [InlineData("bottleneck-detection")]
    [InlineData("project-health")]
    public async Task AnalyzeProject_ReturnsServiceUnavailable_WhenMlIsDisconnected(string route)
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);

        // Act
        var response = await client.PostAsJsonAsync($"/api/projects/{project}/ai/{route}", new AiAnalysisRequest());

        // Assert
        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
        var result = await response.Content.ReadFromJsonAsync<ApiResponse<object>>();
        Assert.NotNull(result);
        Assert.False(result.Success);
        Assert.Equal("The ML service is not connected yet.", result.Message);
    }

    // Verifies that delay-prediction returns the adapter's response.
    [Fact]
    public async Task PredictDelay_ReturnsResult_WhenAdapterSucceeds()
    {
        // Arrange
        var mlService = new TestMlService();
        using var factory = new Factory(mlService);
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);

        // Act
        var response = await client.PostAsJsonAsync($"/api/projects/{project}/ai/delay-prediction", new AiAnalysisRequest());

        // Assert
        var data = await ResponseData(response);
        Assert.Equal(project, data.GetProperty("projectId").GetInt32());
        Assert.Equal(0.7m, data.GetProperty("delayProbability").GetDecimal());
    }

    // Verifies that risk-analysis returns the adapter's response.
    [Fact]
    public async Task AnalyzeRisk_ReturnsResult_WhenAdapterSucceeds()
    {
        // Arrange
        var mlService = new TestMlService();
        using var factory = new Factory(mlService);
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);

        // Act
        var response = await client.PostAsJsonAsync($"/api/projects/{project}/ai/risk-analysis", new AiAnalysisRequest());

        // Assert
        var data = await ResponseData(response);
        Assert.Equal(project, data.GetProperty("projectId").GetInt32());
        Assert.Equal(0.6m, data.GetProperty("riskScore").GetDecimal());
    }

    // Verifies that bottleneck-detection returns the adapter's response.
    [Fact]
    public async Task DetectBottlenecks_ReturnsResult_WhenAdapterSucceeds()
    {
        // Arrange
        var mlService = new TestMlService();
        using var factory = new Factory(mlService);
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);
        await CreatedId(await client.PostAsJsonAsync($"/api/projects/{project}/tasks", new TaskRequest { Title = "Task" }));

        // Act
        var response = await client.PostAsJsonAsync($"/api/projects/{project}/ai/bottleneck-detection", new AiAnalysisRequest());

        // Assert
        var data = await ResponseData(response);
        Assert.Equal(project, data.GetProperty("projectId").GetInt32());
        Assert.Single(data.GetProperty("bottlenecks").EnumerateArray());
    }

    // Verifies that project-health returns the adapter's response.
    [Fact]
    public async Task GetProjectHealth_ReturnsResult_WhenAdapterSucceeds()
    {
        // Arrange
        var mlService = new TestMlService();
        using var factory = new Factory(mlService);
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);

        // Act
        var response = await client.PostAsJsonAsync($"/api/projects/{project}/ai/project-health", new AiAnalysisRequest());

        // Assert
        var data = await ResponseData(response);
        Assert.Equal(project, data.GetProperty("projectId").GetInt32());
        Assert.Equal(75m, data.GetProperty("healthScore").GetDecimal());
    }

    // Verifies project isolation and exclusion of deleted tasks in one place.
    [Fact]
    public async Task PrepareAiInput_ReturnsOnlyRequestedProjectsActiveTasks()
    {
        // Arrange
        var mlService = new TestMlService();
        using var factory = new Factory(mlService);
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);
        var other = await CreateProgressProject(client);
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ScaleFlowDbContext>();
        db.ProjectTasks.AddRange(
            new ProjectTask { Id = 1, ProjectId = project, Title = "Active", CreatedBy = 1, UpdatedBy = 1 },
            new ProjectTask { Id = 2, ProjectId = other, Title = "Other", CreatedBy = 1, UpdatedBy = 1 },
            new ProjectTask { Id = 3, ProjectId = project, Title = "Deleted", IsDeleted = true, CreatedBy = 1, UpdatedBy = 1 });
        db.TaskDependencies.Add(new TaskDependency { TaskId = 1, DependsOnTaskId = 3 });
        await db.SaveChangesAsync();

        // Act
        await ResponseData(await client.PostAsJsonAsync($"/api/projects/{project}/ai/delay-prediction",
            new AiAnalysisRequest { InputWindowDays = 14 }));

        // Assert
        Assert.NotNull(mlService.LastInput);
        Assert.Equal(project, mlService.LastInput.Project.Id);
        Assert.Equal(14, mlService.LastInput.InputWindowDays);
        Assert.Equal(1, Assert.Single(mlService.LastInput.Tasks).Id);
        Assert.Empty(mlService.LastInput.Dependencies);
    }

    // Verifies that invalid analysis windows are rejected before delegation.
    [Theory]
    [InlineData(0)]
    [InlineData(366)]
    public async Task AnalyzeProject_ReturnsBadRequest_WhenWindowIsInvalid(int window)
    {
        // Arrange
        var mlService = new TestMlService();
        using var factory = new Factory(mlService);
        using var client = await factory.Client();
        var project = await CreateProgressProject(client);

        // Act
        var response = await client.PostAsJsonAsync($"/api/projects/{project}/ai/delay-prediction",
            new AiAnalysisRequest { InputWindowDays = window });

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal(0, mlService.Calls);
    }

    // Verifies that users without project access cannot call the ML adapter.
    [Theory]
    [InlineData(2)]
    [InlineData(3)]
    public async Task AnalyzeProject_ReturnsNotFound_WhenActorCannotAccessProject(int userId)
    {
        // Arrange
        var mlService = new TestMlService();
        using var factory = new Factory(mlService);
        using var owner = await factory.Client();
        using var outsider = await factory.Client(userId);
        var project = await CreateProgressProject(owner);

        // Act
        var response = await outsider.PostAsJsonAsync($"/api/projects/{project}/ai/delay-prediction", new AiAnalysisRequest());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Equal(0, mlService.Calls);
    }
}
