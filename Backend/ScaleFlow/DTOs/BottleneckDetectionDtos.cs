namespace ScaleFlow.DTOs;

public record BottleneckDetectionResponse(int ProjectId, IReadOnlyList<BottleneckTaskResponse> Bottlenecks);

public record BottleneckTaskResponse(int TaskId, decimal Score, string? Explanation);
