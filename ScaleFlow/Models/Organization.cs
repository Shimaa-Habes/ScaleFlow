using System;
using System.Collections.Generic;

namespace ScaleFlow.Models;
public class Organization : SoftDeletableEntity
{
    public string Name { get; set; } = null!;
    public string Slug { get; set; } = null!;
    public string Code { get; set; } = null!;
    public string? Industry { get; set; }
    public string? Timezone { get; set; }

    public ICollection<User> Users { get; set; } = new HashSet<User>();
    public ICollection<Project> Projects { get; set; } = new HashSet<Project>();
    public ICollection<Team> Teams { get; set; } = new HashSet<Team>();
    public ICollection<Role> Roles { get; set; } = new HashSet<Role>();
    public ICollection<ReportTemplate> ReportTemplates { get; set; } = new HashSet<ReportTemplate>();
    public ICollection<AuditLog> AuditLogs { get; set; } = new HashSet<AuditLog>();

    /*
      For SQL Server/PostgreSQL with soft delete, apply filtered unique:
      IsUnique() with filter IsDeleted = false.
    */
}



