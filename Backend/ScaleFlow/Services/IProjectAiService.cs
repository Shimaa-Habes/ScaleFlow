using System.Security.Claims;
using ScaleFlow.DTOs;

namespace ScaleFlow.Services;

public interface IProjectAiService
{
    Task<DelayPredictionResponse> PredictDelay(ClaimsPrincipal user, int projectId, AiAnalysisRequest request, CancellationToken cancellationToken);
    Task<RiskAnalysisResponse> AnalyzeRisk(ClaimsPrincipal user, int projectId, AiAnalysisRequest request, CancellationToken cancellationToken);
    Task<BottleneckDetectionResponse> DetectBottlenecks(ClaimsPrincipal user, int projectId, AiAnalysisRequest request, CancellationToken cancellationToken);
    Task<AiProjectHealthResponse> GetProjectHealth(ClaimsPrincipal user, int projectId, AiAnalysisRequest request, CancellationToken cancellationToken);
}
