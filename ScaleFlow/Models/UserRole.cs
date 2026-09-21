using System;

namespace ScaleFlow.Models;
public class UserRole
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int RoleId { get; set; }
    public int? ProjectId { get; set; }
    public int? AssignedBy { get; set; }
    public DateTimeOffset AssignedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }
    public User User { get; set; } = null!;
    public Role Role { get; set; } = null!;

    public Project? Project { get; set; }
    public User? AssignedByUser { get; set; }
}



