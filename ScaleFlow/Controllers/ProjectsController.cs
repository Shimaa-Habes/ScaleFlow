using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ScaleFlow.DTOs;
using ScaleFlow.Services;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ProjectsController : ControllerBase
{
    private readonly IProjectService _projectService;

    public ProjectsController(IProjectService projectService)
    {
        _projectService = projectService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] QueryParameters queryParameters, CancellationToken cancellationToken)
    {
        var projects = await _projectService.ListProjects(User, queryParameters.Page, queryParameters.PageSize, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<ProjectResponse>>.Ok(projects));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id, CancellationToken cancellationToken)
    {
        var project = await _projectService.GetProject(User, id, cancellationToken);
        return Ok(ApiResponse<ProjectResponse>.Ok(project));
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] ProjectRequest request, CancellationToken cancellationToken)
    {
        var project = await _projectService.CreateProject(User, request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = project.Id }, ApiResponse<ProjectResponse>.Ok(project, "Project created."));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] ProjectRequest request, CancellationToken cancellationToken)
    {
        var project = await _projectService.UpdateProject(User, id, request, cancellationToken);
        return Ok(ApiResponse<ProjectResponse>.Ok(project, "Project updated."));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken)
    {
        await _projectService.DeleteProject(User, id, cancellationToken);
        return Ok(ApiResponse<object>.Ok(null, "Project deleted."));
    }
}
