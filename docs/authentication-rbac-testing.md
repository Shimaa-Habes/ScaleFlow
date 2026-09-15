# Authentication and RBAC Testing

## Authentication Flow

The ScaleFlow authentication flow is:

```text
Registration
    |
    v
Identity User Creation
    |
    v
Password Hashing (ASP.NET Core Identity)
    |
    v
Login
    |
    v
JWT Generation
    |
    v
JWT Validation
    |
    v
Role Claims (ClaimTypes.Role)
    |
    v
Authorization
```

Public registration creates an active `Client` account. ASP.NET Core Identity validates and hashes the password. Login verifies the hash with `SignInManager`, then issues a signed JWT containing the user identifier, email, name, issuer, audience, expiry, and role claims. JWT Bearer authentication validates the token before `[Authorize]` policies run.

The verification endpoints are:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/test` for any authenticated user
- `GET /api/auth/me` for authenticated user details
- `GET /api/auth/project-manager-only`
- `GET /api/auth/team-leader-only`
- `GET /api/auth/team-member-only`
- `GET /api/auth/client-only`

`UseAuthentication()` runs before `UseAuthorization()`. Swagger is configured with a Bearer security definition.

## Test Results

Executed with .NET 8.0.31:

| Test | Expected | Actual | Status |
|---|---|---|---|
| Valid registration | Client user created | User created with Client role | PASS |
| Password storage | Password is hashed | Identity hash stored; plaintext differs | PASS |
| Duplicate registration | Rejected | `InvalidOperationException` | PASS |
| Valid login | JWT returned | Signed token returned | PASS |
| Invalid password | Rejected | `InvalidOperationException` | PASS |
| Unknown user | Rejected | `InvalidOperationException` | PASS |
| JWT claims | Identity, email, role, issuer, audience, expiry | All present and expiry is future | PASS |
| Supported role claims | All four role claims emitted | ProjectManager, TeamLeader, TeamMember, Client | PASS |
| Protected test endpoint | Requires authentication | `[Authorize]` declared | PASS |
| Role-restricted endpoints | Matching roles required | All four role attributes verified | PASS |

Command:

```text
dotnet test .\ScaleFlow.Tests\ScaleFlow.Tests.csproj --no-restore --verbosity minimal
```

Result: **7 passed, 0 failed**.

## RBAC Results

| Role | Authentication | Authorized endpoint | Wrong-role behavior |
|---|---|---|---|
| ProjectManager | PASS | PASS | Policy declaration verified |
| TeamLeader | PASS | PASS | Policy declaration verified |
| TeamMember | PASS | PASS | Policy declaration verified |
| Client | PASS | PASS | Policy declaration verified |

The ASP.NET Core authorization contract is `401 Unauthorized` when no valid bearer token authenticates the request, `200 OK` for an authenticated request with the required role, and `403 Forbidden` for an authenticated request with a different role. The endpoint attributes are covered by automated tests; full HTTP-host integration tests were not added because the current test project does not reference a web test host package.

## Database Notes

`ScaleFlowDbContext` uses ASP.NET Core Identity tables for users, roles, and user-role assignments. Application startup calls `EnsureCreatedAsync` for a fresh database and idempotently seeds the four system roles. Existing databases are not deleted. No EF migration files were present in the repository, so no migration was created.

## Security Notes

The JWT signing key remains configuration-driven. The checked-in value is a development placeholder and must be replaced through environment configuration or user secrets before deployment. Passwords and JWT values are not logged or stored as plaintext.
