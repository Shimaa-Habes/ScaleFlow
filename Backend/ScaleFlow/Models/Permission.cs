using System;
using System.Collections.Generic;

namespace ScaleFlow.Models;
public class Permission
{
    public int Id { get; set; }
    public string Resource { get; set; } = null!;
    public string Action { get; set; } = null!;
    public string Code { get; set; } = null!;
    public string? Description { get; set; }

    public ICollection<RolePermission> RolePermissions { get; set; } = new HashSet<RolePermission>();
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }
}



