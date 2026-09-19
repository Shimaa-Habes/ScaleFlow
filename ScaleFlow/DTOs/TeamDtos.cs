namespace ScaleFlow.DTOs;

public class TeamRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int? LeadUserId { get; set; }
}

public class AddTeamMemberRequest
{
    public int UserId { get; set; }
    public string? RoleInTeam { get; set; }
}

public class UpdateTeamMemberRequest
{
    public string? RoleInTeam { get; set; }
}

public record TeamResponse(int Id, int ProjectId, string Name, string? Description,
    int? LeadUserId, string? LeadName, int MemberCount, DateTimeOffset CreatedAt, DateTimeOffset? UpdatedAt);

public record TeamMemberResponse(int Id, int TeamId, int UserId, string FullName,
    string? AvatarUrl, string? JobTitle, bool IsActive, string? RoleInTeam, DateTimeOffset JoinedAt);
