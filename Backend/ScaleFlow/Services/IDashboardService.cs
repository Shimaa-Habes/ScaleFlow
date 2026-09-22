using System.Security.Claims;
using ScaleFlow.DTOs;

namespace ScaleFlow.Services;

public interface IDashboardService
{
    Task<DashboardOverviewResponse> GetOverview(
        ClaimsPrincipal user,
        CancellationToken cancellationToken);
}