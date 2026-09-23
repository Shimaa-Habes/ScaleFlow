namespace ScaleFlow.Models;

public class ProjectArchitecture
{
    public int Id { get; set; }

    public int ProjectId { get; set; }

    public string? Frontend { get; set; }
    public string? Backend { get; set; }
    public string? Database { get; set; }
    public string? Authentication { get; set; }
    public string? AiMl { get; set; }
    public string? RealTime { get; set; }
    public string? ExternalServices { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }

    public Project Project { get; set; } = null!;
}