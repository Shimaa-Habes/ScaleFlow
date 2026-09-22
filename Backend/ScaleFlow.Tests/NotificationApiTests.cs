using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ScaleFlow.DTOs;
using ScaleFlow.Models;
using ScaleFlow.Services;
using Xunit;

namespace ScaleFlow.Tests;

public partial class ManagementApiTests
{
    [Fact]
    public async Task Notifications_ListAndSummary_ReturnsAccurateCountForRecipient()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client(1);

        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<ScaleFlowDbContext>();
            db.Notifications.AddRange(
                new Notification
                {
                    RecipientUserId = 1,
                    ActorUserId = 2,
                    Type = "TaskAssigned",
                    Title = "Task 1",
                    Message = "Assigned",
                    TargetType = "Task",
                    TargetId = 10,
                    CreatedAt = DateTimeOffset.UtcNow
                },
                new Notification
                {
                    RecipientUserId = 1,
                    ActorUserId = 2,
                    Type = "ProjectUpdated",
                    Title = "Project Update",
                    Message = "Updated",
                    TargetType = "Project",
                    TargetId = 1,
                    ReadAt = DateTimeOffset.UtcNow.AddMinutes(-5),
                    CreatedAt = DateTimeOffset.UtcNow.AddMinutes(-10)
                },
                new Notification
                {
                    RecipientUserId = 2, // Belongs to user 2
                    Type = "System",
                    Title = "Other user notif",
                    Message = "Msg",
                    TargetType = "System",
                    TargetId = 0,
                    CreatedAt = DateTimeOffset.UtcNow
                }
            );
            await db.SaveChangesAsync();
        }

        // Act
        var listResponse = await client.GetAsync("/api/notifications");
        var unreadOnlyResponse = await client.GetAsync("/api/notifications?unreadOnly=true");
        var summaryResponse = await client.GetAsync("/api/notifications/unread-count");

        // Assert
        Assert.Equal(HttpStatusCode.OK, listResponse.StatusCode);
        var listJson = await ResponseData(listResponse);
        Assert.Equal(2, listJson.GetArrayLength()); // User 1 has only 2 notifications

        var unreadJson = await ResponseData(unreadOnlyResponse);
        Assert.Equal(1, unreadJson.GetArrayLength()); // Only 1 unread

        var summaryJson = await ResponseData(summaryResponse);
        Assert.Equal(1, summaryJson.GetProperty("unreadCount").GetInt32());
        Assert.Equal(2, summaryJson.GetProperty("totalCount").GetInt32());
    }

    [Fact]
    public async Task Notifications_MarkAsRead_UpdatesReadAtTimestamp_AndProtectsOwnership()
    {
        // Arrange
        using var factory = new Factory();
        using var client1 = await factory.Client(1);
        using var client2 = await factory.Client(2);

        int notifId;
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<ScaleFlowDbContext>();
            var notif = new Notification
            {
                RecipientUserId = 1,
                Type = "TaskAssigned",
                Title = "Task 1",
                Message = "Assigned",
                TargetType = "Task",
                TargetId = 10,
                CreatedAt = DateTimeOffset.UtcNow
            };
            db.Notifications.Add(notif);
            await db.SaveChangesAsync();
            notifId = notif.Id;
        }

        // Act - User 2 tries to mark User 1's notification as read
        var forbiddenAttempt = await client2.PutAsync($"/api/notifications/{notifId}/read", null);
        Assert.Equal(HttpStatusCode.NotFound, forbiddenAttempt.StatusCode);

        // Act - User 1 marks own notification
        var markReadResponse = await client1.PutAsync($"/api/notifications/{notifId}/read", null);
        Assert.Equal(HttpStatusCode.OK, markReadResponse.StatusCode);

        var data = await ResponseData(markReadResponse);
        Assert.NotNull(data.GetProperty("readAt").GetString());

        // Verify in DB
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<ScaleFlowDbContext>();
            var updated = await db.Notifications.FindAsync(notifId);
            Assert.NotNull(updated!.ReadAt);
        }
    }

    [Fact]
    public async Task Notifications_MarkAllAsRead_ClearsAllUnread()
    {
        // Arrange
        using var factory = new Factory();
        using var client = await factory.Client(1);

        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<ScaleFlowDbContext>();
            db.Notifications.AddRange(
                new Notification
                {
                    RecipientUserId = 1,
                    Type = "T1",
                    Title = "N1",
                    Message = "M1",
                    TargetType = "Task",
                    TargetId = 1,
                    CreatedAt = DateTimeOffset.UtcNow
                },
                new Notification
                {
                    RecipientUserId = 1,
                    Type = "T2",
                    Title = "N2",
                    Message = "M2",
                    TargetType = "Task",
                    TargetId = 2,
                    CreatedAt = DateTimeOffset.UtcNow
                }
            );
            await db.SaveChangesAsync();
        }

        // Act
        var response = await client.PutAsync("/api/notifications/read-all", null);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var summaryResponse = await client.GetAsync("/api/notifications/unread-count");
        var summary = await ResponseData(summaryResponse);
        Assert.Equal(0, summary.GetProperty("unreadCount").GetInt32());
    }
}
