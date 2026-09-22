using System;

namespace ScaleFlow.Models;

public abstract class SoftDeletableEntity : EntityBase
{
    public bool IsDeleted { get; set; } = false;
    public DateTimeOffset? DeletedAt { get; set; }
    public int? DeletedBy { get; set; }
}



