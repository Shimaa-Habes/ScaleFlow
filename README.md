# ScaleFlow API

ScaleFlow is an ASP.NET Core 8 Web API for organization-scoped project and task management.

## Run locally

From the `ScaleFlow` directory:

```powershell
dotnet run --urls "https://localhost:7233;http://localhost:5233"
```

The application requires the configured `ScaleFlowConnection` SQL Server connection string. Swagger is available at `/swagger` when `ASPNETCORE_ENVIRONMENT=Development`.

## Authentication

Register and log in through:

- `POST /api/auth/register`
- `POST /api/auth/login`

Send the returned JWT on protected requests:

```text
Authorization: Bearer <access-token>
```

## Core API authorization

| Endpoint | Allowed roles | Resource boundary |
|---|---|---|
| `GET /api/projects` | ProjectManager, TeamLeader, TeamMember, Client | Same organization and owner/member |
| `POST /api/projects` | ProjectManager | Created in caller organization; caller owns it |
| `GET /api/projects/{projectId}` | Any authenticated role | Same organization and owner/member |
| `PUT /api/projects/{projectId}` | ProjectManager | Same organization and owner/member |
| `DELETE /api/projects/{projectId}` | ProjectManager | Same organization and project owner |
| `GET /api/projects/{projectId}/tasks` | Any authenticated role | Accessible project member/owner |
| `POST /api/projects/{projectId}/tasks` | ProjectManager, TeamLeader | Accessible project member/owner |
| `GET /api/projects/{projectId}/tasks/{taskId}` | Any authenticated role | Accessible project and matching task |
| `PUT /api/projects/{projectId}/tasks/{taskId}` | ProjectManager, TeamLeader, TeamMember | Accessible project; TeamMember must be creator or assignee |
| `DELETE /api/projects/{projectId}/tasks/{taskId}` | ProjectManager, TeamLeader | Accessible project member/owner |

An authenticated user with the wrong role receives `403 Forbidden`. A missing or invalid JWT receives `401 Unauthorized`. Cross-organization and non-member resource lookups return `404 Not Found` to avoid disclosing resource existence.

## Tests

Run all tests from the repository root:

```powershell
dotnet test .\ScaleFlow.Tests\ScaleFlow.Tests.csproj
```

The automated suite covers authentication, role metadata, authorized reads, `401`, `403`, cross-organization access, non-member access, and invalid task assignments. See [HANDS-ON-LAB.md](HANDS-ON-LAB.md) for manual API checks and known limitations.
