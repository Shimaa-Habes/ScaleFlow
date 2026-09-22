using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.DTOs;
using ScaleFlow.Models;

namespace ScaleFlow.Services;

public class ProjectAiService : IProjectAiService
{
    private readonly ScaleFlowDbContext _context;
    private readonly IProjectService _projectService;
    private readonly IMlService _mlService;

    public ProjectAiService(ScaleFlowDbContext context, IProjectService projectService, IMlService mlService)
    {
        _context = context;
        _projectService = projectService;
        _mlService = mlService;
    }

    // Authorizes the caller before preparing project-scoped DTOs for the ML adapter.
    private async Task<AiProjectInput> PrepareInput(ClaimsPrincipal user, int projectId, AiAnalysisRequest request, CancellationToken ct)
    {
        var project = await _projectService.GetProject(user, projectId, ct);
        var tasks = await _context.ProjectTasks
            .AsNoTracking()
            .Where(task => task.ProjectId == projectId)
            .OrderBy(task => task.Id)
            .Select(task => new AiTaskInput(task.Id, task.Title, task.Status, task.Priority,
                task.PlannedStart, task.PlannedEnd, task.ActualStart, task.ActualEnd,
                task.EstimatedHours, task.ActualHours, task.CompletionPercent))
            .ToListAsync(ct);
        var dependencies = await _context.TaskDependencies
            .AsNoTracking()
            .Where(dependency => dependency.Task!.ProjectId == projectId &&
                dependency.DependsOnTask!.ProjectId == projectId)
            .OrderBy(dependency => dependency.Id)
            .Select(dependency => new AiDependencyInput(dependency.TaskId, dependency.DependsOnTaskId,
                dependency.DependencyType, dependency.LagDays))
            .ToListAsync(ct);
        return new AiProjectInput(project, request.InputWindowDays, tasks, dependencies);
    }

    // Delegates delay prediction without generating or storing synthetic results.
    public async Task<DelayPredictionResponse> PredictDelay(ClaimsPrincipal user, int projectId, AiAnalysisRequest request, CancellationToken ct)
    {
        var input = await PrepareInput(user, projectId, request, ct);
        return await _mlService.PredictDelay(input, ct);
    }

    // Delegates project risk analysis through the integration interface.
    public async Task<RiskAnalysisResponse> AnalyzeRisk(ClaimsPrincipal user, int projectId, AiAnalysisRequest request, CancellationToken ct)
    {
        var input = await PrepareInput(user, projectId, request, ct);
        return await _mlService.AnalyzeRisk(input, ct);
    }

    // Delegates bottleneck detection using only the requested project's data.
    public async Task<BottleneckDetectionResponse> DetectBottlenecks(ClaimsPrincipal user, int projectId, AiAnalysisRequest request, CancellationToken ct)
    {
        var input = await PrepareInput(user, projectId, request, ct);
        return await _mlService.DetectBottlenecks(input, ct);
    }

    // Keeps AI health analysis separate from deterministic project progress.
    public async Task<AiProjectHealthResponse> GetProjectHealth(ClaimsPrincipal user, int projectId, AiAnalysisRequest request, CancellationToken ct)
    {
        var input = await PrepareInput(user, projectId, request, ct);
        return await _mlService.GetProjectHealth(input, ct);
    }
}
