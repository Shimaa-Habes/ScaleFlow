using System;

namespace ScaleFlow.Models;
public class ProjectHealthSnapshot
{
    public int Id { get; set; }
    public int ProjectId { get; set; }
    public DateTimeOffset SnapshotDate { get; set; } = DateTimeOffset.UtcNow;
    public decimal? HealthScore { get; set; }
    public int RiskCount { get; set; }
    public int OverdueTasksCount { get; set; }
    public decimal? Velocity { get; set; }
    public decimal? Throughput { get; set; }
    public decimal? OpenRiskRatio { get; set; }
    public decimal? TeamUtilizationAvg { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public Project Project { get; set; } = null!;
}



