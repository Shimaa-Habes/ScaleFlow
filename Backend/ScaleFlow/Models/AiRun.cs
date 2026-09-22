using System;
using System.Collections.Generic;

namespace ScaleFlow.Models;
public class AiRun
{
    public int Id { get; set; }
    public int ProjectId { get; set; }
    public AiTriggerType TriggerType { get; set; } = AiTriggerType.Scheduled;
    public string? ModelName { get; set; }
    public AiRunStatus Status { get; set; } = AiRunStatus.Pending;
    public DateTimeOffset? StartedAt { get; set; }
    public DateTimeOffset? FinishedAt { get; set; }
    public int? InputWindowDays { get; set; }
    public string? MetadataJson { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public Project Project { get; set; } = null!;
    public ICollection<AiPrediction> Predictions { get; set; } = new HashSet<AiPrediction>();
}



