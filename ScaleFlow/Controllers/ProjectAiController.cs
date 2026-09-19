using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ScaleFlow.DTOs;
using ScaleFlow.Services;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/projects/{projectId}/ai")]
[Authorize]
public class ProjectAiController : ControllerBase
{
    private readonly IProjectAiService _aiService;

    public ProjectAiController(IProjectAiService aiService)
    {
        _aiService = aiService;
    }

    [HttpPost("delay-prediction")]
    public async Task<IActionResult> PredictDelay(int projectId, [FromBody] AiAnalysisRequest request, CancellationToken cancellationToken)
    {
        var result = await _aiService.PredictDelay(User, projectId, request, cancellationToken);
        return Ok(ApiResponse<DelayPredictionResponse>.Ok(result));
    }

    [HttpPost("risk-analysis")]
    public async Task<IActionResult> AnalyzeRisk(int projectId, [FromBody] AiAnalysisRequest request, CancellationToken cancellationToken)
    {
        var result = await _aiService.AnalyzeRisk(User, projectId, request, cancellationToken);
        return Ok(ApiResponse<RiskAnalysisResponse>.Ok(result));
    }

    [HttpPost("bottleneck-detection")]
    public async Task<IActionResult> DetectBottlenecks(int projectId, [FromBody] AiAnalysisRequest request, CancellationToken cancellationToken)
    {
        var result = await _aiService.DetectBottlenecks(User, projectId, request, cancellationToken);
        return Ok(ApiResponse<BottleneckDetectionResponse>.Ok(result));
    }

    [HttpPost("project-health")]
    public async Task<IActionResult> GetProjectHealth(int projectId, [FromBody] AiAnalysisRequest request, CancellationToken cancellationToken)
    {
        var result = await _aiService.GetProjectHealth(User, projectId, request, cancellationToken);
        return Ok(ApiResponse<AiProjectHealthResponse>.Ok(result));
    }
}
