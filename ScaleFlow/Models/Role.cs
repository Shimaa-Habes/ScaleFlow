using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Identity;

namespace ScaleFlow.Models;

public class Role : IdentityRole<int>
{
    public int? OrganizationId { get; set; }
    public string Code { get; set; } = null!;
    public RoleScope Scope { get; set; } = RoleScope.Global;
    public string? Description { get; set; }
    public bool IsSystem { get; set; } = false;
    public bool IsDeleted { get; set; } = false;
    public DateTimeOffset? DeletedAt { get; set; }
    public int? DeletedBy { get; set; }

    public Organization? Organization { get; set; }
}
