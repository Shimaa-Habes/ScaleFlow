using ScaleFlow.Models;

namespace ScaleFlow.Services;

public interface IJwtTokenService
{
    string GenerateToken(User user, IEnumerable<string> roles);
}
