namespace ScaleFlow.DTOs;

public record RiskAnalysisResponse(int ProjectId, decimal RiskScore, decimal Confidence, string? Explanation);
