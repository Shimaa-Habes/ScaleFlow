using System;

namespace ScaleFlow.Models;
public class ProjectMember
{
    public int Id { get; set; }
    public int ProjectId { get; set; }
    public int UserId { get; set; }
    public DateTimeOffset JoinedAt { get; set; } = DateTimeOffset.UtcNow;
    public bool IsBlocked { get; set; } = false;
    public decimal? HourlyRate { get; set; }
    public string? RoleOverride { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }
    public Project Project { get; set; } = null!;
    public User User { get; set; } = null!;
}



