using System;

namespace ScaleFlow.Models;
public class WorkloadSnapshot
{
    public int Id { get; set; }
    public int ProjectId { get; set; }
    public int UserId { get; set; }
    public DateTimeOffset PeriodStart { get; set; }
    public DateTimeOffset PeriodEnd { get; set; }
    public decimal? PlannedHours { get; set; }
    public decimal? ActualHours { get; set; }
    public decimal? UtilizationRatio { get; set; }
    public decimal? OverloadScore { get; set; }
    public Project Project { get; set; } = null!;
    public User User { get; set; } = null!;
}



