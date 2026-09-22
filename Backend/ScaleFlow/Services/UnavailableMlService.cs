using ScaleFlow.DTOs;
using ScaleFlow.Middleware;

namespace ScaleFlow.Services;

// Replace this adapter when the ML service and its API contract are ready.
public class UnavailableMlService : IMlService
{
    private static Task<T> Unavailable<T>(CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        return Task.FromException<T>(new ApiException(503, "The ML service is not connected yet."));
    }

    public Task<DelayPredictionResponse> PredictDelay(AiProjectInput request, CancellationToken cancellationToken) =>
        Unavailable<DelayPredictionResponse>(cancellationToken);

    public Task<RiskAnalysisResponse> AnalyzeRisk(AiProjectInput request, CancellationToken cancellationToken) =>
        Unavailable<RiskAnalysisResponse>(cancellationToken);

    public Task<BottleneckDetectionResponse> DetectBottlenecks(AiProjectInput request, CancellationToken cancellationToken) =>
        Unavailable<BottleneckDetectionResponse>(cancellationToken);

    public Task<AiProjectHealthResponse> GetProjectHealth(AiProjectInput request, CancellationToken cancellationToken) =>
        Unavailable<AiProjectHealthResponse>(cancellationToken);
}
