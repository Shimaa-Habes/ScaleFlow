using System;

namespace ScaleFlow.Models;
public class AuditLog
{
    public int Id { get; set; }
    public int? UserId { get; set; }
    public int OrganizationId { get; set; }
    public string Action { get; set; } = null!;
    public string EntityType { get; set; } = null!;
    public int? EntityId { get; set; }
    public string? ChangesJson { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public User? User { get; set; }
    public Organization Organization { get; set; } = null!;
}



