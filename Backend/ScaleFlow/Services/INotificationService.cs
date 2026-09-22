using System.Security.Claims;
using ScaleFlow.DTOs;

namespace ScaleFlow.Services;

public interface INotificationService
{
    Task<IReadOnlyList<NotificationResponse>> ListNotifications(ClaimsPrincipal user, bool? unreadOnly, int page, int pageSize, CancellationToken ct);
    Task<NotificationSummaryResponse> GetNotificationSummary(ClaimsPrincipal user, CancellationToken ct);
    Task<NotificationResponse> MarkAsRead(ClaimsPrincipal user, int id, CancellationToken ct);
    Task<int> MarkAllAsRead(ClaimsPrincipal user, CancellationToken ct);
    Task<NotificationResponse> CreateNotification(int recipientUserId, int? actorUserId, string type, string title, string message, string targetType, int targetId, int? projectId, CancellationToken ct);
}
