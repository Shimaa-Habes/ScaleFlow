# Hands-On Lab: Secure Core Project and Task APIs

## Objectives

Verify JWT authentication, role-based access control, organization isolation, project membership, and ownership rules for the Project and Task APIs.

## Prerequisites

- .NET 8 SDK
- SQL Server configured by `ScaleFlowConnection`
- Development environment enabled for Swagger
- A seeded organization and users with the `ProjectManager`, `TeamLeader`, `TeamMember`, and `Client` roles

Start the API from the `ScaleFlow` directory:

```powershell
$env:ASPNETCORE_ENVIRONMENT = "Development"
dotnet run --urls "http://localhost:5233"
```

Open Swagger at `http://localhost:5233/swagger`.

## Authorization matrix

| Operation | ProjectManager | TeamLeader | TeamMember | Client |
|---|---:|---:|---:|---:|
| View projects | Yes, if owner/member | Yes, if owner/member | Yes, if owner/member | Yes, if owner/member |
| Create project | Yes | No | No | No |
| Update project | Yes, if accessible | No | No | No |
| Delete project | Yes, owner only | No | No | No |
| View tasks | Yes, if project member/owner | Yes, if project member/owner | Yes, if project member/owner | Yes, if project member/owner |
| Create task | Yes, if project member/owner | Yes, if project member/owner | No | No |
| Update task | Yes, if project member/owner | Yes, if project member/owner | Yes, if creator or assignee | No |
| Delete task | Yes, if project member/owner | Yes, if project member/owner | No | No |

The role names are the existing system roles. This implementation does not add or change role permissions.

## Test procedure

1. Register or obtain JWTs for users in the same organization and in a different organization.
2. Log in with each user using `POST /api/auth/login`.
3. In Swagger, select **Authorize** and enter `Bearer <token>`.
4. Create a project with a Project Manager token.
5. Confirm the Project Manager can view and update the project.
6. Confirm a Client token can view an accessible project but cannot create one.
7. Add a Team Leader or Team Member to the project through the existing data setup.
8. Confirm Team Leader can create and delete tasks.
9. Confirm an assigned Team Member can update the task.
10. Confirm a Client cannot update or delete the task.

Example request bodies:

```json
{
  "name": "API Security Project",
  "description": "Authorization lab",
  "status": 1,
  "priority": 2
}
```

```json
{
  "title": "Verify membership boundary",
  "description": "Access-controlled task",
  "status": 1,
  "priority": 2,
  "type": 1
}
```

## Expected authentication responses

### 401 Unauthorized

Call a protected endpoint without an `Authorization` header, or with an expired/invalid JWT:

```powershell
Invoke-WebRequest http://localhost:5233/api/projects -Method Get
```

Expected result: `401 Unauthorized`.

### 403 Forbidden

Call `POST /api/projects` with a valid Client JWT. The endpoint requires the existing `ProjectManager` role:

```powershell
$headers = @{ Authorization = "Bearer $clientToken" }
$body = @{ name = "Client attempt" } | ConvertTo-Json
Invoke-WebRequest http://localhost:5233/api/projects -Method Post -Headers $headers -ContentType "application/json" -Body $body
```

Expected result: `403 Forbidden`. The token is valid, but the role does not satisfy the endpoint requirement.

The same status applies when an authenticated user has an insufficient role for task creation, task deletion, project update, or project deletion.

## Organization and membership boundaries

- Project queries require the caller's organization to match `Project.OrganizationId`.
- Project reads require the caller to be the owner or an active, non-blocked `ProjectMember`.
- Task endpoints first verify access to the parent project.
- Task reads require both the accessible project and the requested task's `ProjectId` to match.
- Project deletion requires ownership in addition to the Project Manager role.
- Team Member task updates require task creation or an active assignment.
- Cross-organization and non-member requests return `404 Not Found` rather than revealing whether a resource exists.
- Invalid task assignees are rejected before the task is persisted.

## Automated verification

From the repository root:

```powershell
dotnet test .\ScaleFlow.Tests\ScaleFlow.Tests.csproj
```

The suite covers the existing authentication tests and project/task authorization tests, including valid access, `401`, `403`, cross-organization access, non-member access, role metadata, and invalid-assignee persistence.

## Known limitations

- The current test project does not reference `Microsoft.AspNetCore.Mvc.Testing`, so automated tests invoke controllers directly rather than hosting the complete HTTP pipeline.
- Full HTTP verification should be added when a test host, test database, and isolated startup configuration are available.
- Project and task authorization currently uses controller logic and the shared base class rather than named policy handlers.
- Swagger is registered only in the Development environment.
- The API requires SQL Server startup configuration and applies EF migrations during application startup.
