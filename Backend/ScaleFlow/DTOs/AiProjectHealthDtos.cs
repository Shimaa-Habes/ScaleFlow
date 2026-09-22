namespace ScaleFlow.DTOs;

public record AiProjectHealthResponse(int ProjectId, decimal HealthScore, int RiskCount,
    int OverdueTasksCount, decimal Confidence, string? Explanation);
