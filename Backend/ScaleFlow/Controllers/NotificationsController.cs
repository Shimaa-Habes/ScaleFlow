using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ScaleFlow.DTOs;
using ScaleFlow.Services;

namespace ScaleFlow.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public NotificationsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] QueryParameters queryParameters,
        [FromQuery] bool? unreadOnly,
        CancellationToken cancellationToken)
    {
        var notifications = await _notificationService.ListNotifications(
            User, unreadOnly, queryParameters.Page, queryParameters.PageSize, cancellationToken);

        return Ok(ApiResponse<IReadOnlyList<NotificationResponse>>.Ok(notifications));
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount(CancellationToken cancellationToken)
    {
        var summary = await _notificationService.GetNotificationSummary(User, cancellationToken);
        return Ok(ApiResponse<NotificationSummaryResponse>.Ok(summary));
    }

    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary(CancellationToken cancellationToken)
    {
        var summary = await _notificationService.GetNotificationSummary(User, cancellationToken);
        return Ok(ApiResponse<NotificationSummaryResponse>.Ok(summary));
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(int id, CancellationToken cancellationToken)
    {
        var notification = await _notificationService.MarkAsRead(User, id, cancellationToken);
        return Ok(ApiResponse<NotificationResponse>.Ok(notification, "Notification marked as read."));
    }

    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllAsRead(CancellationToken cancellationToken)
    {
        var count = await _notificationService.MarkAllAsRead(User, cancellationToken);
        return Ok(ApiResponse<object>.Ok(new { count }, $"{count} notifications marked as read."));
    }
}
