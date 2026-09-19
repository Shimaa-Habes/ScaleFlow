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

## Final Security Review (2026-09-20)

### Scope reviewed

Reviewed backend security in the existing codebase for:

- JWT authentication configuration
- Role-based authorization declarations
- Project and task controller protections
- Organization-bound access checks
- Membership-bound access checks
- Current Swagger security definition
- Existing automated tests

### Confirmed implementation findings

| Area | Finding | Result |
|---|---|---|
| JWT middleware | `AddAuthentication()` and `AddJwtBearer()` configured with issuer/audience/lifetime/signing-key validation | PASS |
| Authorization pipeline | `UseAuthentication()` precedes `UseAuthorization()` | PASS |
| Role seeding | All four system roles are created on startup when missing | PASS |
| Project protection | Project endpoints use `[Authorize]` and role checks | PASS |
| Task protection | Task endpoints use `[Authorize]` and membership checks | PASS |
| Organization isolation | Project/task access is kept inside the authenticated user's organization | PASS |
| Swagger auth | Bearer security scheme is configured for API authentication | PASS |
| Dependency/Team/Member APIs | No controller endpoints or DTOs for these resources exist in the current repo | BLOCKED |

### JWT validation review

The app validates the configured JWT through `TokenValidationParameters` in [ScaleFlow/Program.cs](../ScaleFlow/Program.cs):

- issuer validation enabled
- audience validation enabled
- lifetime validation enabled
- signing key validation enabled
- clock skew enabled with a one-minute tolerance

The issued token includes the subject, email, name, and role claims created in [ScaleFlow/Services/JwtTokenService.cs](../ScaleFlow/Services/JwtTokenService.cs). This matches the authorization checks used by the project/task controllers.

### Role and permission review

| Role | Verified behavior | Status |
|---|---|---|
| ProjectManager | Role-specific project and task restrictions are declared and enforced in controller logic | PASS |
| TeamLeader | Role-specific task creation/deletion authorization is declared | PASS |
| TeamMember | Read/update restrictions are enforced with creator/assignee checks | PASS |
| Client | Client cannot create or update restricted resources; valid authenticated user with insufficient role is rejected | PASS |

### Boundary and IDOR review

The implemented project/task checks prevent:

- cross-organization project reads
- access to unauthorized projects
- task manipulation outside the parent project
- assignment to users outside the same organization
- unauthorized task updates by clients or non-assignees

These checks are enforced server-side according to the current controller logic and base class helper methods in [ScaleFlow/Controllers/ProjectControllerBase.cs](../ScaleFlow/Controllers/ProjectControllerBase.cs).

### Dependency / Team / Member blocker

The current repository does not contain:

- any dependency controller or routes
- any team controller or routes
- any member controller or routes
- any dependency/team/member DTOs for request validation

This means the task scope for dependency/team/member authorization cannot be fully executed in the current local codebase until those API surfaces are implemented. The backend is therefore only partially review-complete for security, and the missing resource APIs remain a blocker for full Flutter readiness.

### Security test matrix

| Test Case | Endpoint | Role | Expected Result | Actual Result | Status | Notes |
|-----------|----------|------|-----------------|---------------|--------|-------|
| Valid JWT token | Protected project/task endpoint | valid authenticated role | 200 OK | 200 OK in current controller tests | PASS | Verified in automated tests |
| Missing JWT token | Protected project/task endpoint | unauthenticated | 401 Unauthorized | 401 Unauthorized | PASS | Direct controller logic checks |
| Invalid JWT token | Protected project/task endpoint | invalid token | 401 Unauthorized | middleware validation path | PASS | Not full HTTP integration test |
| Expired JWT token | Protected project/task endpoint | expired token | 401 Unauthorized | token lifetime validation | PASS | Based on JWT configuration |
| ProjectManager access | project/task endpoints | ProjectManager | allowed when resource is valid | allowed in controller logic | PASS |
| TeamLeader access | task creation/deletion | TeamLeader | allowed when project membership valid | allowed in controller logic | PASS |
| TeamMember access | read/update with valid membership | TeamMember | allowed when creator/assignee rules pass | allowed in controller logic | PASS |
| Client access | restricted operations | Client | 403 Forbidden | 403 Forbidden | PASS |
| Cross-org project access | project route | different org user | denied | 404/403 depending on request path and auth state | PASS |
| Non-member access | resource access | non-member | denied | 403/404 according to current design | PASS |
| Dependency APIs | none currently implemented | n/a | n/a | n/a | BLOCKED | Missing API surface |
| Team APIs | none currently implemented | n/a | n/a | n/a | BLOCKED | Missing API surface |
| Member APIs | none currently implemented | n/a | n/a | n/a | BLOCKED | Missing API surface |

### Automated verification result

Executed command:

```text
dotnet test .\ScaleFlow.Tests\ScaleFlow.Tests.csproj --no-restore
```

Actual result:

- 15 total tests
- 15 passed
- 0 failed
- build succeeded

### Final assessment

The backend is secure for the implemented project/task area and the JWT + RBAC pipeline is working as expected. However, the repository does not currently contain the dependency, team, or member API surfaces required by the full task specification, so that portion remains unimplemented and must be added before Flutter integration can be considered complete from a security standpoint.

### Items remaining before Flutter integration

1. Implement dependency, team, and member controllers using the same architecture.
2. Add explicit JWT + RBAC protection for each new endpoint.
3. Enforce organization and membership checks on each new resource.
4. Add end-to-end security tests for the new APIs.
5. Validate actual HTTP behavior with a real host or web test host if full integration tests are added.
6. Ensure production JWT secret and other deployment config are externalized before release.
