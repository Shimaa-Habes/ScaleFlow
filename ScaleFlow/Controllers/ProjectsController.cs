using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.Constants;
using ScaleFlow.DTOs;
using ScaleFlow.Models;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/projects")]
public sealed class ProjectsController : ProjectControllerBase
{
    public ProjectsController(ScaleFlowDbContext dbContext) : base(dbContext)
    {
    }

    [Authorize]
    [HttpGet]
    public async Task<IActionResult> GetProjects(CancellationToken cancellationToken)
    {
        if (!IsAuthenticated || CurrentUserId is null)
        {
            return Unauthorized();
        }

        var userId = CurrentUserId.Value;
        var organizationId = await GetCurrentUserOrganizationIdAsync(cancellationToken);

        if (organizationId is null)
        {
            return Forbid();
        }

        var projects = await DbContext.Projects
            .AsNoTracking()
            .Where(project => !project.IsDeleted && project.OrganizationId == organizationId.Value &&
                (project.OwnerId == userId || project.Members.Any(member =>
                    member.UserId == userId && !member.IsBlocked)))
            .ToListAsync(cancellationToken);

        return Ok(projects);
    }

    [Authorize]
    [HttpGet("{projectId:int}")]
    public async Task<IActionResult> GetProject(int projectId, CancellationToken cancellationToken)
    {
        if (!IsAuthenticated || CurrentUserId is null)
        {
            return Unauthorized();
        }

        var organizationId = await GetCurrentUserOrganizationIdAsync(cancellationToken);
        if (organizationId is null)
        {
            return Forbid();
        }

        var project = await DbContext.Projects
            .Include(project => project.Members)
            .SingleOrDefaultAsync(project => !project.IsDeleted && project.Id == projectId && project.OrganizationId == organizationId.Value, cancellationToken);

        if (project is null)
        {
            return NotFound();
        }

        var isAuthorized = project.OwnerId == CurrentUserId.Value || project.Members.Any(member => member.UserId == CurrentUserId.Value && !member.IsBlocked);
        return isAuthorized ? Ok(project) : Forbid();
    }

    [Authorize(Roles = RoleConstants.ProjectManager)]
    [HttpPost]
    public async Task<IActionResult> CreateProject(CreateProjectRequest request, CancellationToken cancellationToken)
    {
        if (!IsAuthenticated || CurrentUserId is not int userId)
        {
            return Unauthorized();
        }

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return BadRequest("Project name is required.");
        }

        var organizationId = await DbContext.Set<User>()
            .Where(user => user.Id == userId && user.IsActive && !user.IsDeleted)
            .Select(user => (int?)user.OrganizationId)
            .SingleOrDefaultAsync(cancellationToken);

        if (organizationId is null)
        {
            return Forbid();
        }

        var project = new Project
        {
            OrganizationId = organizationId.Value,
            OwnerId = userId,
            Name = request.Name.Trim(),
            Description = request.Description,
            Status = request.Status,
            Priority = request.Priority,
            Budget = request.Budget,
            StartDate = request.StartDate,
            EndDate = request.EndDate
        };

        DbContext.Projects.Add(project);
        await DbContext.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(GetProject), new { projectId = project.Id }, project);
    }

    [Authorize(Roles = RoleConstants.ProjectManager)]
    [HttpPut("{projectId:int}")]
    public async Task<IActionResult> UpdateProject(int projectId, UpdateProjectRequest request, CancellationToken cancellationToken)
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

        if (project.OwnerId != userId && !IsProjectManager)
        {
            return Forbid();
        }

        project.Name = request.Name.Trim();
        project.Description = request.Description;
        project.Status = request.Status;
        project.Priority = request.Priority;
        project.Budget = request.Budget;
        project.StartDate = request.StartDate;
        project.EndDate = request.EndDate;
        project.IsArchived = request.IsArchived;
        project.UpdatedAt = DateTimeOffset.UtcNow;
        await DbContext.SaveChangesAsync(cancellationToken);
        return Ok(project);
    }

    [Authorize(Roles = RoleConstants.ProjectManager)]
    [HttpDelete("{projectId:int}")]
    public async Task<IActionResult> DeleteProject(int projectId, CancellationToken cancellationToken)
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

        if (project.OwnerId != userId)
        {
            return Forbid();
        }

        project.IsDeleted = true;
        project.DeletedAt = DateTimeOffset.UtcNow;
        project.DeletedBy = userId;
        await DbContext.SaveChangesAsync(cancellationToken);
        return NoContent();
    }
}