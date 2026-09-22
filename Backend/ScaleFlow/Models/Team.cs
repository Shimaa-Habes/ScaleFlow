using System;
using System.Collections.Generic;

namespace ScaleFlow.Models;
public class Team
{
    public int Id { get; set; }
    public int OrganizationId { get; set; }
    public int? ProjectId { get; set; }
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public int? LeadUserId { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }
    public Organization Organization { get; set; } = null!;
    public Project? Project { get; set; }
    public User? LeadUser { get; set; }
    public ICollection<TeamMember> Members { get; set; } = new HashSet<TeamMember>();
}



