using System.ComponentModel.DataAnnotations;

namespace ScaleFlow.DTOs;

public class UpdateProfileRequest
{
    [Required]
    [StringLength(200)]
    public string FullName { get; set; } = string.Empty;

    [StringLength(100)]
    public string? JobTitle { get; set; }

    [StringLength(200)]
    public string? Company { get; set; }

    [StringLength(100)]
    public string? Department { get; set; }

    [Phone]
    [StringLength(30)]
    public string? Phone { get; set; }

    [StringLength(100)]
    public string? Country { get; set; }

    [StringLength(100)]
    public string? City { get; set; }

    [StringLength(1000)]
    public string? ShortBio { get; set; }

    [StringLength(50)]
    public string? Language { get; set; }

    [StringLength(50)]
    public string? DefaultView { get; set; }

    public bool NotificationsEnabled { get; set; }
}

public class ProfileResponse
{
    public int UserId { get; set; }

    public string Email { get; set; } = string.Empty;

    public string FullName { get; set; } = string.Empty;

    public string? JobTitle { get; set; }

    public string? Role { get; set; }

    public string? Company { get; set; }

    public string? Department { get; set; }

    public string? Phone { get; set; }

    public string? Country { get; set; }

    public string? City { get; set; }

    public string? ShortBio { get; set; }

    public string? Language { get; set; }

    public string DefaultView { get; set; } = "Projects";

    public bool NotificationsEnabled { get; set; }

    public string? AvatarUrl { get; set; }
}

