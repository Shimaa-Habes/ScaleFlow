using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ScaleFlow.DTOs;
using ScaleFlow.Services;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/projects/{projectId}/[controller]")]
[Authorize]
public class TasksController : ControllerBase
{
    private readonly ITaskService _taskService;

    public TasksController(ITaskService taskService)
    {
        _taskService = taskService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(int projectId, [FromQuery] QueryParameters queryParameters, CancellationToken cancellationToken)
    {
        var tasks = await _taskService.ListTasks(User, projectId, queryParameters.Page, queryParameters.PageSize, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<TaskResponse>>.Ok(tasks));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int projectId, int id, CancellationToken cancellationToken)
    {
        var task = await _taskService.GetTask(User, projectId, id, cancellationToken);
        return Ok(ApiResponse<TaskResponse>.Ok(task));
    }

    [HttpPost]
    public async Task<IActionResult> Create(int projectId, [FromBody] TaskRequest request, CancellationToken cancellationToken)
    {
        var task = await _taskService.CreateTask(User, projectId, request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { projectId, id = task.Id }, ApiResponse<TaskResponse>.Ok(task, "Task created."));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int projectId, int id, [FromBody] TaskRequest request, CancellationToken cancellationToken)
    {
        var task = await _taskService.UpdateTask(User, projectId, id, request, cancellationToken);
        return Ok(ApiResponse<TaskResponse>.Ok(task, "Task updated."));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int projectId, int id, CancellationToken cancellationToken)
    {
        await _taskService.DeleteTask(User, projectId, id, cancellationToken);
        return Ok(ApiResponse<object>.Ok(null, "Task deleted."));
    }

    [HttpGet("{taskId}/dependencies")]
    public async Task<IActionResult> GetDependencies(int projectId, int taskId, CancellationToken cancellationToken)
    {
        var dependencies = await _taskService.ListDependencies(User, projectId, taskId, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<TaskDependencyResponse>>.Ok(dependencies));
    }

    [HttpGet("{taskId}/dependencies/{id}")]
    public async Task<IActionResult> GetDependency(int projectId, int taskId, int id, CancellationToken cancellationToken)
    {
        var dependency = await _taskService.GetDependency(User, projectId, taskId, id, cancellationToken);
        return Ok(ApiResponse<TaskDependencyResponse>.Ok(dependency));
    }

    [HttpPost("{taskId}/dependencies")]
    public async Task<IActionResult> CreateDependency(int projectId, int taskId, [FromBody] TaskDependencyRequest request, CancellationToken cancellationToken)
    {
        var dependency = await _taskService.CreateDependency(User, projectId, taskId, request, cancellationToken);
        return CreatedAtAction(nameof(GetDependency), new { projectId, taskId, id = dependency.Id },
            ApiResponse<TaskDependencyResponse>.Ok(dependency, "Dependency created."));
    }

    [HttpPut("{taskId}/dependencies/{id}")]
    public async Task<IActionResult> UpdateDependency(int projectId, int taskId, int id, [FromBody] TaskDependencyRequest request, CancellationToken cancellationToken)
    {
        var dependency = await _taskService.UpdateDependency(User, projectId, taskId, id, request, cancellationToken);
        return Ok(ApiResponse<TaskDependencyResponse>.Ok(dependency, "Dependency updated."));
    }

    [HttpDelete("{taskId}/dependencies/{id}")]
    public async Task<IActionResult> DeleteDependency(int projectId, int taskId, int id, CancellationToken cancellationToken)
    {
        await _taskService.DeleteDependency(User, projectId, taskId, id, cancellationToken);
        return Ok(ApiResponse<object>.Ok(null, "Dependency deleted."));
    }
}
