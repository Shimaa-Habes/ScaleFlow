using System;

namespace ScaleFlow.Models;
public class TaskAttachment
{
    public int Id { get; set; }
    public int TaskId { get; set; }
    public int UploaderId { get; set; }
    public string FileName { get; set; } = null!;
    public string FileUrl { get; set; } = null!;
    public string? FileType { get; set; }
    public long? SizeBytes { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public ProjectTask Task { get; set; } = null!;
    public User Uploader { get; set; } = null!;
}



