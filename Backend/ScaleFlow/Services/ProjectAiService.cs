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

    public ProjectAiService(
        ScaleFlowDbContext context,
        IProjectService projectService,
        IMlService mlService)
    {
        _context = context;
        _projectService = projectService;
        _mlService = mlService;
    }

    private async Task<AiProjectInput> PrepareInput(
        ClaimsPrincipal user,
        int projectId,
        AiAnalysisRequest request,
        CancellationToken ct)
    {
        var project = await _projectService.GetProject(
            user,
            projectId,
            ct);

        var tasks = await _context.ProjectTasks
            .AsNoTracking()
            .Where(task =>
                task.ProjectId == projectId &&
                !task.IsDeleted)
            .OrderBy(task => task.Id)
            .Select(task => new AiTaskInput(
                task.Id,
                task.Title,
                task.Status,
                task.Priority,
                task.PlannedStart,
                task.PlannedEnd,
                task.ActualStart,
                task.ActualEnd,
                task.EstimatedHours,
                task.ActualHours,
                task.CompletionPercent))
            .ToListAsync(ct);

        var dependencies = await _context.TaskDependencies
            .AsNoTracking()
            .Where(dependency =>
                dependency.Task != null &&
                dependency.DependsOnTask != null &&
                dependency.Task.ProjectId == projectId &&
                dependency.DependsOnTask.ProjectId == projectId)
            .OrderBy(dependency => dependency.Id)
            .Select(dependency => new AiDependencyInput(
                dependency.TaskId,
                dependency.DependsOnTaskId,
                dependency.DependencyType,
                dependency.LagDays))
            .ToListAsync(ct);

        var teamSize =
            await _context.ProjectMembers
                .AsNoTracking()
                .Where(member =>
                    member.ProjectId == projectId &&
                    !member.IsBlocked &&
                    !member.User.IsDeleted &&
                    member.User.IsActive)
                .Select(member => member.UserId)
                .Distinct()
                .CountAsync(ct);

        // Include the project owner in the effective team size.
        var ownerAlreadyMember =
            await _context.ProjectMembers
                .AsNoTracking()
                .AnyAsync(member =>
                    member.ProjectId == projectId &&
                    member.UserId == project.OwnerId &&
                    !member.IsBlocked,
                    ct);

        if (!ownerAlreadyMember)
        {
            teamSize++;
        }

        return new AiProjectInput(
            project,
            request.InputWindowDays,
            tasks,
            dependencies,
            teamSize);
    }

    public async Task<DelayPredictionResponse> PredictDelay(
        ClaimsPrincipal user,
        int projectId,
        AiAnalysisRequest request,
        CancellationToken ct)
    {
        var input = await PrepareInput(
            user,
            projectId,
            request,
            ct);

        return await _mlService.PredictDelay(
            input,
            ct);
    }

    public async Task<RiskAnalysisResponse> AnalyzeRisk(
        ClaimsPrincipal user,
        int projectId,
        AiAnalysisRequest request,
        CancellationToken ct)
    {
        var input = await PrepareInput(
            user,
            projectId,
            request,
            ct);

        return await _mlService.AnalyzeRisk(
            input,
            ct);
    }

    public async Task<BottleneckDetectionResponse> DetectBottlenecks(
        ClaimsPrincipal user,
        int projectId,
        AiAnalysisRequest request,
        CancellationToken ct)
    {
        var input = await PrepareInput(
            user,
            projectId,
            request,
            ct);

        return await _mlService.DetectBottlenecks(
            input,
            ct);
    }

    public async Task<AiProjectHealthResponse> GetProjectHealth(
        ClaimsPrincipal user,
        int projectId,
        AiAnalysisRequest request,
        CancellationToken ct)
    {
        var input = await PrepareInput(
            user,
            projectId,
            request,
            ct);

        return await _mlService.GetProjectHealth(
            input,
            ct);
    }
}