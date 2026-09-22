using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.DTOs;
using ScaleFlow.Hubs;
using ScaleFlow.Middleware;
using ScaleFlow.Models;

namespace ScaleFlow.Services;

public class NotificationService : INotificationService
{
    private readonly ScaleFlowDbContext _context;
    private readonly IHubContext<ScaleFlowHub> _hubContext;

    public NotificationService(ScaleFlowDbContext context, IHubContext<ScaleFlowHub> hubContext)
    {
        _context = context;
        _hubContext = hubContext;
    }

    private static int GetUserId(ClaimsPrincipal user)
    {
        var userIdClaim = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (user.Identity?.IsAuthenticated != true || !int.TryParse(userIdClaim, out var userId) || userId <= 0)
        {
            throw new ApiException(401, "Invalid user identity.");
        }

        return userId;
    }

    public async Task<IReadOnlyList<NotificationResponse>> ListNotifications(
        ClaimsPrincipal user, bool? unreadOnly, int page, int pageSize, CancellationToken ct)
    {
        var userId = GetUserId(user);

        var query = _context.Notifications
            .AsNoTracking()
            .Where(n => n.RecipientUserId == userId);

        if (unreadOnly == true)
        {
            query = query.Where(n => n.ReadAt == null);
        }

        return await query
            .OrderByDescending(n => n.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(n => new NotificationResponse(
                n.Id,
                n.RecipientUserId,
                n.ActorUserId,
                n.ActorUser != null ? n.ActorUser.FullName : null,
                n.Type,
                n.Title,
                n.Message,
                n.TargetType,
                n.TargetId,
                n.ProjectId,
                n.ReadAt,
                n.CreatedAt))
            .ToListAsync(ct);
    }

    public async Task<NotificationSummaryResponse> GetNotificationSummary(ClaimsPrincipal user, CancellationToken ct)
    {
        var userId = GetUserId(user);

        var total = await _context.Notifications.CountAsync(n => n.RecipientUserId == userId, ct);
        var unread = await _context.Notifications.CountAsync(n => n.RecipientUserId == userId && n.ReadAt == null, ct);

        return new NotificationSummaryResponse(unread, total);
    }

    public async Task<NotificationResponse> MarkAsRead(ClaimsPrincipal user, int id, CancellationToken ct)
    {
        var userId = GetUserId(user);

        var notification = await _context.Notifications
            .Include(n => n.ActorUser)
            .SingleOrDefaultAsync(n => n.Id == id && n.RecipientUserId == userId, ct)
            ?? throw new ApiException(404, "Notification not found.");

        if (notification.ReadAt == null)
        {
            notification.ReadAt = DateTimeOffset.UtcNow;
            await _context.SaveChangesAsync(ct);
        }

        return new NotificationResponse(
            notification.Id,
            notification.RecipientUserId,
            notification.ActorUserId,
            notification.ActorUser?.FullName,
            notification.Type,
            notification.Title,
            notification.Message,
            notification.TargetType,
            notification.TargetId,
            notification.ProjectId,
            notification.ReadAt,
            notification.CreatedAt);
    }

    public async Task<int> MarkAllAsRead(ClaimsPrincipal user, CancellationToken ct)
    {
        var userId = GetUserId(user);

        var unreadNotifications = await _context.Notifications
            .Where(n => n.RecipientUserId == userId && n.ReadAt == null)
            .ToListAsync(ct);

        var now = DateTimeOffset.UtcNow;
        foreach (var notification in unreadNotifications)
        {
            notification.ReadAt = now;
        }

        await _context.SaveChangesAsync(ct);
        return unreadNotifications.Count;
    }

    public async Task<NotificationResponse> CreateNotification(
        int recipientUserId,
        int? actorUserId,
        string type,
        string title,
        string message,
        string targetType,
        int targetId,
        int? projectId,
        CancellationToken ct)
    {
        var notification = new Notification
        {
            RecipientUserId = recipientUserId,
            ActorUserId = actorUserId,
            Type = type,
            Title = title,
            Message = message,
            TargetType = targetType,
            TargetId = targetId,
            ProjectId = projectId,
            CreatedAt = DateTimeOffset.UtcNow
        };

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync(ct);

        string? actorName = null;
        if (actorUserId.HasValue)
        {
            actorName = await _context.Users
                .Where(u => u.Id == actorUserId.Value)
                .Select(u => u.FullName)
                .SingleOrDefaultAsync(ct);
        }

        var response = new NotificationResponse(
            notification.Id,
            notification.RecipientUserId,
            notification.ActorUserId,
            actorName,
            notification.Type,
            notification.Title,
            notification.Message,
            notification.TargetType,
            notification.TargetId,
            notification.ProjectId,
            notification.ReadAt,
            notification.CreatedAt);

        // Real-time broadcast to user group
        await _hubContext.Clients.Group($"user_{recipientUserId}")
            .SendAsync("NotificationReceived", response, ct);

        return response;
    }
}
