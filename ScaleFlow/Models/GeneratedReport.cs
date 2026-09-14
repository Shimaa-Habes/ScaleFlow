using System;

namespace ScaleFlow.Models;
public class GeneratedReport
{
    public int Id { get; set; }
    public int ProjectId { get; set; }
    public int? TemplateId { get; set; }
    public int? CreatedBy { get; set; }
    public string Title { get; set; } = null!;
    public DateTimeOffset? PeriodFrom { get; set; }
    public DateTimeOffset? PeriodTo { get; set; }
    public string? SummaryText { get; set; }
    public string? FileUrl { get; set; }
    public string? ReportJson { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public Project Project { get; set; } = null!;
    public ReportTemplate? Template { get; set; }
    public User? CreatedByUser { get; set; }
}



