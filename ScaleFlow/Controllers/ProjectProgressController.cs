using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ScaleFlow.DTOs;
using ScaleFlow.Services;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/projects/{projectId}/progress")]
[Authorize]
public class ProjectProgressController : ControllerBase
{
    private readonly IProjectProgressService _progressService;

    public ProjectProgressController(IProjectProgressService progressService)
    {
        _progressService = progressService;
    }

    [HttpGet]
    public async Task<IActionResult> Get(int projectId, CancellationToken cancellationToken)
    {
        var progress = await _progressService.GetProgress(User, projectId, cancellationToken);
        return Ok(ApiResponse<ProjectProgressResponse>.Ok(progress));
    }
}
