using System.Security.Claims;
using ScaleFlow.DTOs;

namespace ScaleFlow.Services;

public interface IReportService
{
    Task<GeneratedReportResponse> GenerateReport(ClaimsPrincipal user, int projectId, GenerateReportRequest request, CancellationToken ct);
    Task<IReadOnlyList<GeneratedReportResponse>> ListReports(ClaimsPrincipal user, int projectId, int page, int pageSize, CancellationToken ct);
    Task<GeneratedReportResponse> GetReport(ClaimsPrincipal user, int projectId, int id, CancellationToken ct);
}
