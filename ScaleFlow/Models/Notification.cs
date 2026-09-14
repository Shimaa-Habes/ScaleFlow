using System;

namespace ScaleFlow.Models;
public class Notification
{
    public int Id { get; set; }
    public int RecipientUserId { get; set; }
    public int? ActorUserId { get; set; }
    public string Type { get; set; } = null!;
    public string Title { get; set; } = null!;
    public string Message { get; set; } = null!;
    public string TargetType { get; set; } = null!;
    public int TargetId { get; set; }
    public int? ProjectId { get; set; }
    public DateTimeOffset? ReadAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public User RecipientUser { get; set; } = null!;
    public User? ActorUser { get; set; }
    public Project? Project { get; set; }
}



