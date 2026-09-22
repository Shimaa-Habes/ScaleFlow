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
    public async Task Reports_GenerateAndRetrieveReport_GeneratesStructuredJson()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client(1);
        var projectId = await CreateProgressProject(client);

        // Add some tasks
        var path = $"/api/projects/{projectId}/tasks";
        await client.PostAsJsonAsync(path, new TaskRequest
        {
            Title = "Task Done",
            Status = TaskStatus.Done,
            CompletionPercent = 100,
            EstimatedHours = 10
        });

        await client.PostAsJsonAsync(path, new TaskRequest
        {
            Title = "Task Blocked",
            Status = TaskStatus.Blocked,
            EstimatedHours = 8
        });

        // Act 1: Generate FullAi Report
        var request = new GenerateReportRequest("Q4 Sprint Report", "FullAi");
        var generateResponse = await client.PostAsJsonAsync($"/api/projects/{projectId}/reports/generate", request);

        // Assert 1
        Assert.Equal(HttpStatusCode.Created, generateResponse.StatusCode);
        var reportId = await CreatedId(generateResponse);

        // Act 2: Get Report By Id
        var getResponse = await client.GetAsync($"/api/projects/{projectId}/reports/{reportId}");
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);
        var reportData = await ResponseData(getResponse);

        Assert.Equal("Q4 Sprint Report", reportData.GetProperty("title").GetString());
        Assert.NotNull(reportData.GetProperty("summaryText").GetString());
        Assert.NotNull(reportData.GetProperty("reportJson").GetString());

        // Parse ReportJson to verify structured content
        var jsonDoc = JsonDocument.Parse(reportData.GetProperty("reportJson").GetString()!);
        Assert.True(jsonDoc.RootElement.TryGetProperty("summary", out var summaryProp));
        Assert.True(jsonDoc.RootElement.TryGetProperty("risks", out var risksProp));
        Assert.True(jsonDoc.RootElement.TryGetProperty("aiRecommendations", out var aiRecsProp));

        // Act 3: List Reports
        var listResponse = await client.GetAsync($"/api/projects/{projectId}/reports");
        Assert.Equal(HttpStatusCode.OK, listResponse.StatusCode);
        var listData = await ResponseData(listResponse);
        Assert.True(listData.GetArrayLength() >= 1);
    }

    [Theory]
    [InlineData("{\"title\":\"\"}")]
    [InlineData("{\"title\":\"Report\",\"reportType\":\"InvalidType\"}")]
    [InlineData("{\"title\":\"Report\",\"periodFrom\":\"2026-10-10T00:00:00Z\",\"periodTo\":\"2026-10-01T00:00:00Z\"}")]
    public async Task Reports_GenerateReport_ValidationRejectsInvalidPayload(string payload)
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client(1);
        var projectId = await CreateProgressProject(client);

        // Act
        var content = new StringContent(payload, System.Text.Encoding.UTF8, "application/json");
        var response = await client.PostAsync($"/api/projects/{projectId}/reports/generate", content);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var result = await response.Content.ReadFromJsonAsync<ApiResponse<object>>();
        Assert.NotNull(result);
        Assert.False(result.Success);
        Assert.NotNull(result.Errors);
    }

    [Fact]
    public async Task Reports_NonAccessibleProject_ReturnsNotFound()
    {
        // Arrange
        using var factory = new Factory();
        using var owner = await factory.Client(1);
        using var outsider = await factory.Client(3); // User 3 in Org 2
        var projectId = await CreateProgressProject(owner);

        // Act: Outsider tries to list and generate reports
        var listResponse = await outsider.GetAsync($"/api/projects/{projectId}/reports");
        var generateResponse = await outsider.PostAsJsonAsync(
            $"/api/projects/{projectId}/reports/generate",
            new GenerateReportRequest("Hacked Report"));

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, listResponse.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, generateResponse.StatusCode);
    }
}
