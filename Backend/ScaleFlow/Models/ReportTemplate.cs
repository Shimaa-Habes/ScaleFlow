using System;

namespace ScaleFlow.Models;
public class ReportTemplate
{
    public int Id { get; set; }
    public int OrganizationId { get; set; }
    public string Name { get; set; } = null!;
    public string? Category { get; set; }
    public string? TemplatePayloadJson { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }
    public Organization Organization { get; set; } = null!;
    public ICollection<GeneratedReport> GeneratedReports { get; set; } = new HashSet<GeneratedReport>();
}



