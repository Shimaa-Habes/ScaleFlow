using ScaleFlow.DTOs;

namespace ScaleFlow.Services;

public interface IMlService
{
    Task<DelayPredictionResponse> PredictDelay(AiProjectInput request, CancellationToken cancellationToken);
    Task<RiskAnalysisResponse> AnalyzeRisk(AiProjectInput request, CancellationToken cancellationToken);
    Task<BottleneckDetectionResponse> DetectBottlenecks(AiProjectInput request, CancellationToken cancellationToken);
    Task<AiProjectHealthResponse> GetProjectHealth(AiProjectInput request, CancellationToken cancellationToken);
}
