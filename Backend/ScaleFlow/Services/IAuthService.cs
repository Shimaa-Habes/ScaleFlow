using ScaleFlow.DTOs;
using ScaleFlow.Models;

namespace ScaleFlow.Services;

public interface IAuthService
{
    Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default);
    Task<User?> FindUserByEmailAsync(string email, CancellationToken cancellationToken = default);
}
