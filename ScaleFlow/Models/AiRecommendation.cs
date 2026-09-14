using System;

namespace ScaleFlow.Models;
public class AiRecommendation
{
    public int Id { get; set; }
    public int AiPredictionId { get; set; }
    public string Title { get; set; } = null!;
    public string Details { get; set; } = null!;
    public RecommendationPriority Priority { get; set; } = RecommendationPriority.Medium;
    public int? OwnerUserId { get; set; }
    public RecommendationStatus Status { get; set; } = RecommendationStatus.Open;
    public DateTimeOffset? DueBy { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }
    public AiPrediction AiPrediction { get; set; } = null!;
    public User? OwnerUser { get; set; }
}



