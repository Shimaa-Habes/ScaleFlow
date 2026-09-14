using System;
using System.Collections.Generic;

namespace ScaleFlow.Models;
public class Role : SoftDeletableEntity
{
    public int? OrganizationId { get; set; }
    public string Name { get; set; } = null!;
    public string Code { get; set; } = null!;
    public RoleScope Scope { get; set; } = RoleScope.Global;
    public string? Description { get; set; }
    public bool IsSystem { get; set; } = false;

    public Organization? Organization { get; set; }
    public ICollection<RolePermission> RolePermissions { get; set; } = new HashSet<RolePermission>();
    public ICollection<UserRole> UserRoles { get; set; } = new HashSet<UserRole>();

    /*
      For SQL Server/PostgreSQL with soft delete, apply filtered unique:
      unique index on Code where IsDeleted = 0.
    */
}



