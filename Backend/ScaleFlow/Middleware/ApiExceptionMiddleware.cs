using Microsoft.EntityFrameworkCore;
using ScaleFlow.DTOs;

namespace ScaleFlow.Middleware;

public class ApiException(int statusCode, string message) : Exception(message)
{
    public int StatusCode { get; } = statusCode;
}
public class ApiExceptionMiddleware(RequestDelegate next, ILogger<ApiExceptionMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try { await next(context); }
        catch (OperationCanceledException) when (context.RequestAborted.IsCancellationRequested) { }
        catch (Exception exception) when (!context.Response.HasStarted)
        {
            var (status, message) = exception switch
            {
                ApiException error => (error.StatusCode, error.Message),
                DbUpdateException => (409, "The operation conflicts with existing database records."),
                _ => (500, "An unexpected error occurred.")
            };
            if (status == 500) logger.LogError(exception, "Unhandled API error. TraceId: {TraceId}", context.TraceIdentifier);
            context.Response.Clear();
            context.Response.StatusCode = status;
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Fail(message), context.RequestAborted);
        }
    }
}
