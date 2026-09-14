using System;

namespace ScaleFlow.Models;
public class TeamMember
{
    public int Id { get; set; }
    public int TeamId { get; set; }
    public int UserId { get; set; }
    public string? RoleInTeam { get; set; }
    public DateTimeOffset JoinedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public Team Team { get; set; } = null!;
    public User User { get; set; } = null!;
}



