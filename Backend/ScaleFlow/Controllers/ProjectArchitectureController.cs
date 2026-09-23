using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.DTOs;
using ScaleFlow.Models;

namespace ScaleFlow.Controllers;

[ApiController]
[Authorize]
[Route("api/projects/{projectId}/architecture")]
public class ProjectArchitectureController : ControllerBase
{
    private readonly ScaleFlowDbContext _context;

    public ProjectArchitectureController(ScaleFlowDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> Get(int projectId)
    {
        var architecture = await _context.ProjectArchitectures
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.ProjectId == projectId);

        if (architecture == null)
        {
            return Ok(new
            {
                success = true,
                data = (object?)null
            });
        }

        return Ok(new
        {
            success = true,
            data = new ProjectArchitectureResponse(
                architecture.Id,
                architecture.ProjectId,
                architecture.Frontend,
                architecture.Backend,
                architecture.Database,
                architecture.Authentication,
                architecture.AiMl,
                architecture.RealTime,
                architecture.ExternalServices,
                architecture.CreatedAt,
                architecture.UpdatedAt
            )
        });
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        int projectId,
        [FromBody] ProjectArchitectureRequest request)
    {
        var projectExists = await _context.Projects
            .AnyAsync(x => x.Id == projectId && !x.IsDeleted);

        if (!projectExists)
        {
            return NotFound(new
            {
                success = false,
                message = "Project not found."
            });
        }

        var existing = await _context.ProjectArchitectures
            .FirstOrDefaultAsync(x => x.ProjectId == projectId);

        if (existing != null)
        {
            return Conflict(new
            {
                success = false,
                message = "Architecture already exists for this project."
            });
        }

        var architecture = new ProjectArchitecture
        {
            ProjectId = projectId,
            Frontend = request.Frontend,
            Backend = request.Backend,
            Database = request.Database,
            Authentication = request.Authentication,
            AiMl = request.AiMl,
            RealTime = request.RealTime,
            ExternalServices = request.ExternalServices,
            CreatedAt = DateTimeOffset.UtcNow
        };

        _context.ProjectArchitectures.Add(architecture);

        await _context.SaveChangesAsync();

        return Ok(new
        {
            success = true,
            message = "Project architecture created successfully.",
            data = new ProjectArchitectureResponse(
                architecture.Id,
                architecture.ProjectId,
                architecture.Frontend,
                architecture.Backend,
                architecture.Database,
                architecture.Authentication,
                architecture.AiMl,
                architecture.RealTime,
                architecture.ExternalServices,
                architecture.CreatedAt,
                architecture.UpdatedAt
            )
        });
    }

    [HttpPut]
    public async Task<IActionResult> Update(
        int projectId,
        [FromBody] ProjectArchitectureRequest request)
    {
        var architecture = await _context.ProjectArchitectures
            .FirstOrDefaultAsync(x => x.ProjectId == projectId);

        if (architecture == null)
        {
            return NotFound(new
            {
                success = false,
                message = "Architecture not found."
            });
        }

        architecture.Frontend = request.Frontend;
        architecture.Backend = request.Backend;
        architecture.Database = request.Database;
        architecture.Authentication = request.Authentication;
        architecture.AiMl = request.AiMl;
        architecture.RealTime = request.RealTime;
        architecture.ExternalServices = request.ExternalServices;
        architecture.UpdatedAt = DateTimeOffset.UtcNow;

        await _context.SaveChangesAsync();

        return Ok(new
        {
            success = true,
            message = "Project architecture updated successfully.",
            data = new ProjectArchitectureResponse(
                architecture.Id,
                architecture.ProjectId,
                architecture.Frontend,
                architecture.Backend,
                architecture.Database,
                architecture.Authentication,
                architecture.AiMl,
                architecture.RealTime,
                architecture.ExternalServices,
                architecture.CreatedAt,
                architecture.UpdatedAt
            )
        });
    }
}