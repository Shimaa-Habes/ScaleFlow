using ScaleFlow.Models;

namespace ScaleFlow.DTOs;

public class ProjectRequest
{
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public string? WorkspaceUrl { get; set; }

    public int Progress { get; set; } = 0;

    public bool IsAtRisk { get; set; } = false;

    public ProjectStatus Status { get; set; } = ProjectStatus.Planning;

    public ProjectPriority Priority { get; set; } = ProjectPriority.Medium;

    public decimal? Budget { get; set; }

    public DateTimeOffset? StartDate { get; set; }

    public DateTimeOffset? EndDate { get; set; }

    public List<int> MemberUserIds { get; set; } = new();
}

public record ProjectResponse(
    int Id,
    int OrganizationId,
    int OwnerId,
    string Name,
    string? Description,
    string? WorkspaceUrl,
    int Progress,
    bool IsAtRisk,
    string? ImageUrl,
    ProjectStatus Status,
    ProjectPriority Priority,
    decimal? Budget,
    DateTimeOffset? StartDate,
    DateTimeOffset? EndDate,
    DateTimeOffset CreatedAt,
    DateTimeOffset? UpdatedAt
);