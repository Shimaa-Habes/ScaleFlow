using System;
using System.Collections.Generic;

namespace ScaleFlow.Models;
public class AiPrediction
{
    public int Id { get; set; }
    public int AiRunId { get; set; }
    public AiEntityType EntityType { get; set; }
    public int? EntityId { get; set; }
    public string PredictionType { get; set; } = null!;
    public decimal? RiskScore { get; set; }
    public decimal? DelayProbability { get; set; }
    public int? PredictedDelayDays { get; set; }
    public decimal? Confidence { get; set; }
    public string? Explanation { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public AiRun AiRun { get; set; } = null!;
    public ICollection<AiRecommendation> Recommendations { get; set; } = new HashSet<AiRecommendation>();

    /*
      Avoid heavy filtering over MetadataJson/reporting payloads in SQL-side LINQ.
      Keep heavy JSON fields read-oriented.
    */
}



