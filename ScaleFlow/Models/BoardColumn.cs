using System;
using System.Collections.Generic;

namespace ScaleFlow.Models;
public class BoardColumn
{
    public int Id { get; set; }
    public int BoardId { get; set; }
    public string Name { get; set; } = null!;
    public int? WipLimit { get; set; }
    public int Position { get; set; } = 0;
    public bool IsArchived { get; set; } = false;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }
    public Board Board { get; set; } = null!;
    public ICollection<ProjectTask> Tasks { get; set; } = new HashSet<ProjectTask>();
}



