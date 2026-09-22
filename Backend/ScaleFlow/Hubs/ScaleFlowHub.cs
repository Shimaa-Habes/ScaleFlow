using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using ScaleFlow.Models;

namespace ScaleFlow.Hubs;

[Authorize]
public class ScaleFlowHub : Hub
{
    private readonly ScaleFlowDbContext _context;

    public ScaleFlowHub(ScaleFlowDbContext context)
    {
        _context = context;
    }

    private int? CurrentUserId =>
        int.TryParse(Context.User?.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) ? userId : null;

    public override async Task OnConnectedAsync()
    {
        if (CurrentUserId is int userId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
        }

        await base.OnConnectedAsync();
    }

    public async Task JoinProject(int projectId)
    {
        if (CurrentUserId is not int userId)
        {
            throw new HubException("Unauthorized.");
        }

        // Validate that caller has active access to the project
        var hasAccess = await _context.Projects
            .AnyAsync(p => p.Id == projectId && !p.IsDeleted &&
                           (p.OwnerId == userId || p.Members.Any(m => m.UserId == userId && !m.IsBlocked)));

        if (!hasAccess)
        {
            throw new HubException("Project not accessible.");
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, $"project_{projectId}");
    }

    public async Task LeaveProject(int projectId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"project_{projectId}");
    }
}
