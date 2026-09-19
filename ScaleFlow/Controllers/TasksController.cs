using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.Constants;
using ScaleFlow.DTOs;
using ScaleFlow.Models;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/projects/{projectId:int}/tasks")]
public sealed class TasksController : ProjectControllerBase
{
    public TasksController(ScaleFlowDbContext dbContext) : base(dbContext)
    {
    }

    [Authorize]
    [HttpGet]
    public async Task<IActionResult> GetTasks(int projectId, CancellationToken cancellationToken)
    {
        if (!IsAuthenticated || CurrentUserId is null)
        {
            return Unauthorized();
        }

        var project = await FindProjectInOrganizationAsync(projectId, cancellationToken);
        if (project is null)
        {
            return NotFound();
        }

        if (project.OwnerId != CurrentUserId.Value && !project.Members.Any(member => member.UserId == CurrentUserId.Value && !member.IsBlocked))
        {
            return Forbid();
        }

        var tasks = await DbContext.ProjectTasks
            .AsNoTracking()
            .Where(task => task.ProjectId == projectId)
            .ToListAsync(cancellationToken);
        return Ok(tasks);
    }

    [Authorize]
    [HttpGet("{taskId:int}")]
    public async Task<IActionResult> GetTask(int projectId, int taskId, CancellationToken cancellationToken)
    {
        if (!IsAuthenticated || CurrentUserId is null)
        {
            return Unauthorized();
        }

        var project = await FindProjectInOrganizationAsync(projectId, cancellationToken);
        if (project is null)
        {
            return NotFound();
        }

        if (project.OwnerId != CurrentUserId.Value && !project.Members.Any(member => member.UserId == CurrentUserId.Value && !member.IsBlocked))
        {
            return Forbid();
        }

        var task = await DbContext.ProjectTasks
            .AsNoTracking()
            .SingleOrDefaultAsync(item => item.Id == taskId && item.ProjectId == projectId, cancellationToken);
        return task is null ? NotFound() : Ok(task);
    }

    [Authorize(Roles = RoleConstants.ProjectManager + "," + RoleConstants.TeamLeader)]
    [HttpPost]
    public async Task<IActionResult> CreateTask(int projectId, CreateTaskRequest request, CancellationToken cancellationToken)
    {
        if (!IsAuthenticated || CurrentUserId is not int userId)
        {
            return Unauthorized();
        }

        var project = await FindProjectInOrganizationAsync(projectId, cancellationToken);
        if (project is null)
        {
            return NotFound();
        }

        if (project.OwnerId != userId && !project.Members.Any(member => member.UserId == userId && !member.IsBlocked))
        {
            return Forbid();
        }

        if (!IsProjectManager && !IsTeamLeader)
        {
            return Forbid();
        }

        if (request.AssignedUserId is int requestedAssigneeId)
        {
            var assignee = await DbContext.Set<User>()
                .SingleOrDefaultAsync(user =>
                    user.Id == requestedAssigneeId &&
                    user.IsActive &&
                    !user.IsDeleted &&
                    user.OrganizationId == project.OrganizationId,
                    cancellationToken);

            if (assignee is null)
            {
                return BadRequest("Assigned user must belong to the same organization as the project.");
            }

            var isValidAssignee = await DbContext.ProjectMembers.AnyAsync(member =>
                member.ProjectId == projectId &&
                member.UserId == requestedAssigneeId &&
                !member.IsBlocked,
                cancellationToken);

            if (!isValidAssignee)
            {
                return BadRequest("Assigned user must be an active project member.");
            }
        }

        var task = new ProjectTask
        {
            ProjectId = projectId,
            Title = request.Title.Trim(),
            Description = request.Description,
            Status = request.Status,
            Priority = request.Priority,
            Type = request.Type,
            PlannedStart = request.PlannedStart,
            PlannedEnd = request.PlannedEnd,
            EstimatedHours = request.EstimatedHours,
            CreatedBy = userId,
            UpdatedBy = userId
        };

        DbContext.ProjectTasks.Add(task);
        await DbContext.SaveChangesAsync(cancellationToken);

        if (request.AssignedUserId is int assignedUserId)
        {
            DbContext.TaskAssignments.Add(new TaskAssignment
            {
                TaskId = task.Id,
                UserId = assignedUserId,
                AssignedBy = userId,
                IsPrimary = true
            });
            await DbContext.SaveChangesAsync(cancellationToken);
        }

        return CreatedAtAction(nameof(GetTask), new { projectId, taskId = task.Id }, task);
    }

    [Authorize(Roles = RoleConstants.ProjectManager + "," + RoleConstants.TeamLeader + "," + RoleConstants.TeamMember)]
    [HttpPut("{taskId:int}")]
    public async Task<IActionResult> UpdateTask(int projectId, int taskId, UpdateTaskRequest request, CancellationToken cancellationToken)
    {
        if (!IsAuthenticated || CurrentUserId is not int userId)
        {
            return Unauthorized();
        }

        var project = await FindProjectInOrganizationAsync(projectId, cancellationToken);
        if (project is null)
        {
            return NotFound();
        }

        if (project.OwnerId != userId && !project.Members.Any(member => member.UserId == userId && !member.IsBlocked))
        {
            return Forbid();
        }

        var task = await DbContext.ProjectTasks
            .Include(item => item.Assignments)
            .SingleOrDefaultAsync(item => item.Id == taskId && item.ProjectId == projectId, cancellationToken);
        if (task is null)
        {
            return NotFound();
        }

        if (IsClient || (IsTeamMember && task.CreatedBy != userId && !task.Assignments.Any(assignment => assignment.UserId == userId)))
        {
            return Forbid();
        }

        task.Title = request.Title.Trim();
        task.Description = request.Description;
        task.Status = request.Status;
        task.Priority = request.Priority;
        task.Type = request.Type;
        task.PlannedStart = request.PlannedStart;
        task.PlannedEnd = request.PlannedEnd;
        task.EstimatedHours = request.EstimatedHours;
        task.CompletionPercent = request.CompletionPercent;
        task.UpdatedBy = userId;
        task.UpdatedAt = DateTimeOffset.UtcNow;
        await DbContext.SaveChangesAsync(cancellationToken);
        return Ok(task);
    }

    [Authorize(Roles = RoleConstants.ProjectManager + "," + RoleConstants.TeamLeader)]
    [HttpDelete("{taskId:int}")]
    public async Task<IActionResult> DeleteTask(int projectId, int taskId, CancellationToken cancellationToken)
    {
        if (!IsAuthenticated || CurrentUserId is not int userId)
        {
            return Unauthorized();
        }

        var project = await FindProjectInOrganizationAsync(projectId, cancellationToken);
        if (project is null)
        {
            return NotFound();
        }

        if (project.OwnerId != userId && !project.Members.Any(member => member.UserId == userId && !member.IsBlocked))
        {
            return Forbid();
        }

        var task = await DbContext.ProjectTasks
            .SingleOrDefaultAsync(item => item.Id == taskId && item.ProjectId == projectId, cancellationToken);
        if (task is null)
        {
            return NotFound();
        }

        if (!IsProjectManager && !IsTeamLeader)
        {
            return Forbid();
        }

        DbContext.ProjectTasks.Remove(task);
        await DbContext.SaveChangesAsync(cancellationToken);
        return NoContent();
    }
}