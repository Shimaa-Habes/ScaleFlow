namespace ScaleFlow.DTOs;

public record ApiResponse<T>(bool Success, string Message, T? Data,
    IReadOnlyDictionary<string, string[]>? Errors = null)
{
    public static ApiResponse<T> Ok(T? data, string message = "Success") => new(true, message, data);
    public static ApiResponse<T> Fail(string message, IReadOnlyDictionary<string, string[]>? errors = null)
        => new(false, message, default, errors);
}
