using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ScaleFlow.DTOs;
using ScaleFlow.Services;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/projects/{projectId}/reports")]
[Authorize]
public class ProjectReportsController : ControllerBase
{
    private readonly IReportService _reportService;

    public ProjectReportsController(IReportService reportService)
    {
        _reportService = reportService;
    }

    [HttpGet]
    public async Task<IActionResult> ListReports(
        int projectId, [FromQuery] QueryParameters queryParameters, CancellationToken cancellationToken)
    {
        var reports = await _reportService.ListReports(
            User, projectId, queryParameters.Page, queryParameters.PageSize, cancellationToken);

        return Ok(ApiResponse<IReadOnlyList<GeneratedReportResponse>>.Ok(reports));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetReport(int projectId, int id, CancellationToken cancellationToken)
    {
        var report = await _reportService.GetReport(User, projectId, id, cancellationToken);
        return Ok(ApiResponse<GeneratedReportResponse>.Ok(report));
    }

    [HttpPost("generate")]
    public async Task<IActionResult> GenerateReport(
        int projectId, [FromBody] GenerateReportRequest request, CancellationToken cancellationToken)
    {
        var report = await _reportService.GenerateReport(User, projectId, request, cancellationToken);
        return CreatedAtAction(
            nameof(GetReport),
            new { projectId, id = report.Id },
            ApiResponse<GeneratedReportResponse>.Ok(report, "Report generated successfully."));
    }
}
