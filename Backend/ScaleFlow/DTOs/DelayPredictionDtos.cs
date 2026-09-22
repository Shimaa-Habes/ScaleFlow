namespace ScaleFlow.DTOs;

public record DelayPredictionResponse(int ProjectId, decimal DelayProbability,
    int PredictedDelayDays, decimal Confidence, string? Explanation);
