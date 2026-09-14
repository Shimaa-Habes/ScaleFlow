using System;
using System.Collections.Generic;

namespace ScaleFlow.Models;
public class TaskComment
{
    public int Id { get; set; }
    public int TaskId { get; set; }
    public int AuthorId { get; set; }
    public string Content { get; set; } = null!;
    public int? ParentCommentId { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }
    public ProjectTask Task { get; set; } = null!;
    public User Author { get; set; } = null!;
    public TaskComment? ParentComment { get; set; }
    public ICollection<TaskComment> Replies { get; set; } = new HashSet<TaskComment>();
}



