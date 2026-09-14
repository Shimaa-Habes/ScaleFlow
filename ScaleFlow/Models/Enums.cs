
namespace ScaleFlow.Models;

public enum ProjectStatus
{
    Draft = 0,
    Planning = 1,
    Active = 2,
    OnHold = 3,
    Completed = 4,
    Cancelled = 5,
    Archived = 6
}

public enum ProjectPriority
{
    Low = 1,
    Medium = 2,
    High = 3,
    Critical = 4
}

public enum RoleScope
{
    Global = 0,
    Project = 1
}

public enum BoardType
{
    Kanban = 1,
    Timeline = 2,
    Gantt = 3
}

public enum MilestoneStatus
{
    Planned = 1,
    InProgress = 2,
    Completed = 3,
    Delayed = 4,
    Cancelled = 5
}

public enum TaskStatus
{
    Backlog = 1,
    Todo = 2,
    InProgress = 3,
    Review = 4,
    Done = 5,
    Blocked = 6,
    Cancelled = 7
}

public enum TaskPriority
{
    Low = 1,
    Medium = 2,
    High = 3,
    Critical = 4
}

public enum TaskType
{
    Task = 1,
    Bug = 2,
    Feature = 3,
    Research = 4
}

public enum DependencyType
{
    FinishToStart = 1,
    StartToStart = 2,
    FinishToFinish = 3,
    StartToFinish = 4
}

public enum AiTriggerType
{
    Scheduled = 1,
    Manual = 2,
    Webhook = 3
}

public enum AiRunStatus
{
    Pending = 1,
    Running = 2,
    Completed = 3,
    Failed = 4,
    Cancelled = 5
}

public enum AiEntityType
{
    Project = 1,
    Task = 2,
    User = 3,
    Team = 4
}

public enum RecommendationPriority
{
    Low = 1,
    Medium = 2,
    High = 3,
    Critical = 4
}

public enum RecommendationStatus
{
    Open = 1,
    InProgress = 2,
    Done = 3,
    Dismissed = 4
}



