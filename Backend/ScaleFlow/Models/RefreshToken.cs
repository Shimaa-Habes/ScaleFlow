using System;

namespace ScaleFlow.Models;
public class RefreshToken
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string TokenHash { get; set; } = null!;
    public DateTimeOffset ExpiresAt { get; set; }
    public bool IsRevoked { get; set; } = false;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public User User { get; set; } = null!;
}



