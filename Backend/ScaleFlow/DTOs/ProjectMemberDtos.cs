namespace ScaleFlow.DTOs;

public class AddProjectMemberRequest
{
    public int UserId { get; set; }
    public decimal? HourlyRate { get; set; }
    public string? RoleOverride { get; set; }
}

public class UpdateProjectMemberRequest
{
    public bool IsBlocked { get; set; }
    public decimal? HourlyRate { get; set; }
    public string? RoleOverride { get; set; }
}

public record ProjectMemberResponse(int Id, int ProjectId, int UserId, string FullName,
    string? AvatarUrl, string? JobTitle, bool IsActive, bool IsBlocked, decimal? HourlyRate,
    string? RoleOverride, DateTimeOffset JoinedAt);
