using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.DTOs;
using ScaleFlow.Models;
using TaskStatus = ScaleFlow.Models.TaskStatus;

namespace ScaleFlow.Services;

public class ProjectProgressService : IProjectProgressService
{
    private readonly ScaleFlowDbContext _context;
    private readonly IProjectService _projectService;

    public ProjectProgressService(ScaleFlowDbContext context, IProjectService projectService)
    {
        _context = context;
        _projectService = projectService;
    }

    // Calculates live progress without changing task or project state.
    public async Task<ProjectProgressResponse> GetProgress(ClaimsPrincipal user, int projectId, CancellationToken ct)
    {
        await _projectService.GetProject(user, projectId, ct);
        var summary = await _context.ProjectTasks
            .AsNoTracking()
            .Where(task => task.ProjectId == projectId)
            .GroupBy(task => task.ProjectId)
            .Select(tasks => new
            {
                Total = tasks.Count(),
                Completed = tasks.Count(task => task.Status == TaskStatus.Done),
                InProgress = tasks.Count(task => task.Status == TaskStatus.InProgress),
                Blocked = tasks.Count(task => task.Status == TaskStatus.Blocked),
                Cancelled = tasks.Count(task => task.Status == TaskStatus.Cancelled),
                Progress = tasks.Where(task => task.Status != TaskStatus.Cancelled)
                    .Average(task => (decimal?)(task.Status == TaskStatus.Done ? 100 : task.CompletionPercent ?? 0))
            })
            .SingleOrDefaultAsync(ct);

        // Empty projects and projects with only cancelled tasks have zero progress.
        return summary is null
            ? new ProjectProgressResponse(projectId, 0, 0, 0, 0, 0, 0)
            : new ProjectProgressResponse(projectId, summary.Total, summary.Completed, summary.InProgress,
                summary.Blocked, summary.Cancelled, Math.Round(summary.Progress ?? 0, 2));
    }
}
