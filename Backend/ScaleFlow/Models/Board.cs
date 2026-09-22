using System;
using System.Collections.Generic;

namespace ScaleFlow.Models;
public class Board
{
    public int Id { get; set; }
    public int ProjectId { get; set; }
    public string Name { get; set; } = null!;
    public BoardType Type { get; set; } = BoardType.Kanban;
    public bool IsDefault { get; set; } = false;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }
    public Project Project { get; set; } = null!;
    public ICollection<BoardColumn> Columns { get; set; } = new HashSet<BoardColumn>();
}



