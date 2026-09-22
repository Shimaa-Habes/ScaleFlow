using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ScaleFlow.DTOs;
using ScaleFlow.Services;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _dashboardService;

    public DashboardController(IDashboardService dashboardService)
    {
        _dashboardService = dashboardService;
    }

    [HttpGet("Overview")]
    public async Task<IActionResult> GetOverview(
        CancellationToken cancellationToken)
    {
        var overview = await _dashboardService.GetOverview(
            User,
            cancellationToken);

        return Ok(
            ApiResponse<DashboardOverviewResponse>.Ok(overview));
    }
}