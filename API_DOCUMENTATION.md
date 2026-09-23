# ScaleFlow REST API & Real-Time Hub Documentation

Welcome to the official developer documentation for the **ScaleFlow Enterprise Project Management & Predictive AI Platform**. This document serves as the complete technical reference for frontend, mobile (Flutter), and third-party API consumers.

---

## Table of Contents

1. [Overview & Architecture](#1-overview--architecture)
2. [Base URL & Environments](#2-base-url--environments)
3. [Authentication & Authorization](#3-authentication--authorization)
   - [JWT Bearer Authentication](#jwt-bearer-authentication)
   - [Role-Based Access Control (RBAC)](#role-based-access-control-rbac)
   - [Organization Multi-Tenancy](#organization-multi-tenancy)
4. [Standard Response Envelope & Errors](#4-standard-response-envelope--errors)
   - [Success Response Envelope](#success-response-envelope)
   - [Error Response Envelope](#error-response-envelope)
   - [Standard HTTP Status Codes](#standard-http-status-codes)
5. [Common Query Parameters & Pagination](#5-common-query-parameters--pagination)
6. [API Endpoints Reference](#6-api-endpoints-reference)
   - [1. Authentication Module (`/api/auth`)](#1-authentication-module-apiauth)
   - [2. User Profile Module (`/api/profile`)](#2-user-profile-module-apiprofile)
   - [3. Projects Management Module (`/api/projects`)](#3-projects-management-module-apiprojects)
   - [4. Project Members Module (`/api/projects/{projectId}/members`)](#4-project-members-module-apiprojectsprojectidmembers)
   - [5. Tasks Module (`/api/projects/{projectId}/tasks`)](#5-tasks-module-apiprojectsprojectidtasks)
   - [6. Task Dependencies Module (`/api/projects/{projectId}/tasks/{taskId}/dependencies`)](#6-task-dependencies-module-apiprojectsprojectidtaskstaskiddependencies)
   - [7. Teams Module (`/api/projects/{projectId}/teams`)](#7-teams-module-apiprojectsprojectidteams)
   - [8. Project Progress & Milestones Module (`/api/projects/{projectId}/progress`)](#8-project-progress--milestones-module-apiprojectsprojectidprogress)
   - [9. Workload & Task Assignments Module (`/api/projects/{projectId}/workload`)](#9-workload--task-assignments-module-apiprojectsprojectidworkload)
   - [10. Predictive AI Analytics Module (`/api/projects/{projectId}/ai`)](#10-predictive-ai-analytics-module-apiprojectsprojectidai)
   - [11. Reports & Executive Summaries Module (`/api/projects/{projectId}/reports`)](#11-reports--executive-summaries-module-apiprojectsprojectidreports)
   - [12. Notifications Module (`/api/notifications`)](#12-notifications-module-apinotifications)
   - [13. Executive Dashboard Module (`/api/dashboard`)](#13-executive-dashboard-module-apidashboard)
7. [SignalR Real-Time WebSocket Hub (`/hubs/scaleflow`)](#7-signalr-real-time-websocket-hub-hubsscaleflow)
   - [Hub Connection & Authentication](#hub-connection--authentication)
   - [Client Invocation Methods](#client-invocation-methods)
   - [Server Broadcast Events](#server-broadcast-events)
8. [Enumerations & Data Reference](#8-enumerations--data-reference)
9. [Client Integration Examples](#9-client-integration-examples)
   - [Dart / Flutter (Dio / Http)](#dart--flutter-dio--http)
   - [TypeScript / Axios](#typescript--axios)

---

## 1. Overview & Architecture

ScaleFlow delivers enterprise-grade project tracking, AI-driven risk prediction, resource workload optimization, automated milestone reporting, and real-time collaborative updates.

### Key Architectural Highlights
- **ASP.NET Core 8 Web API** backed by SQL Server (EF Core).
- **JWT (JSON Web Token)** authentication with role-based policies.
- **FluentValidation** pipeline filter ensuring strict payload validation.
- **Real-time SignalR Hub** for instant multi-client push notifications and project telemetry.
- **Unified Response Model** (`ApiResponse<T>`) for consistent client-side deserialization across all HTTP status codes.

---

## 2. Base URL & Environments

| Environment | Base URL | Protocol |
|-------------|----------|----------|
| **Development** | `http://localhost:5000` / `https://localhost:5001` | HTTP / HTTPS |
| **Staging** | `https://staging-api.scaleflow.io` | HTTPS |
| **Production** | `https://api.scaleflow.io` | HTTPS |

All REST API routes are prefixed with `/api/`.  
The SignalR Real-Time Hub endpoint is located at `/hubs/scaleflow`.

---

## 3. Authentication & Authorization

### JWT Bearer Authentication

All endpoints—excluding `/api/auth/register` and `/api/auth/login`—require an active JSON Web Token (JWT) sent in the HTTP `Authorization` header:

```http
Authorization: Bearer <your_jwt_access_token>
```

When connecting to the **SignalR Hub** via WebSockets where custom headers cannot always be set, provide the token via the query string:
```text
/hubs/scaleflow?access_token=<your_jwt_access_token>
```

### Role-Based Access Control (RBAC)

ScaleFlow defines 4 core system roles:

| Role Name | Description & Capabilities |
|---|---|
| `ProjectManager` | Full control over projects, team allocations, member permissions, AI forecasts, and executive reports. |
| `TeamLeader` | Leads sub-teams, manages assignments, updates tasks, reviews work items, and monitors member workload. |
| `TeamMember` | Executes assigned tasks, reports progress, and collaborates within permitted projects. |
| `Client` | Read-only stakeholder access to assigned project progress, high-level dashboards, and generated summaries. |

### Organization Multi-Tenancy

Every user belongs to an **Organization** (`OrganizationId`). Projects and tasks are strictly scoped within tenant boundaries:
- A user can only access projects residing in their organization.
- Within an organization, non-owners can only view projects where they are registered as active members (`!IsBlocked`).
- Destructive operations (such as deleting a project) are restricted strictly to the **Project Owner**.

---

## 4. Standard Response Envelope & Errors

Every endpoint in ScaleFlow returns a uniform JSON response envelope conforming to `ApiResponse<T>`.

### Success Response Envelope

```json
{
  "success": true,
  "message": "Project updated.",
  "data": {
    "id": 101,
    "name": "Cloud Migration Phase 2"
  },
  "errors": null
}
```

### Error Response Envelope

When an error occurs (such as validation failures or business logic rejections), `success` is `false`, `data` is `null`, and field-level validation errors are mapped in the `errors` dictionary:

```json
{
  "success": false,
  "message": "Validation failed.",
  "data": null,
  "errors": {
    "Email": [
      "'Email' is not a valid email address."
    ],
    "Password": [
      "'Password' must be at least 8 characters long."
    ]
  }
}
```

### Standard HTTP Status Codes

| Code | Meaning | Reason |
|:---:|---|---|
| `200 OK` | Success | The request succeeded and returned data. |
| `201 Created` | Resource Created | Successful creation with `Location` header pointing to the new resource. |
| `400 Bad Request` | Validation Failure | Request body, query parameter, or file violates schema or logic constraints. |
| `401 Unauthorized` | Missing / Invalid Token | Missing, invalid, or expired Bearer token. |
| `403 Forbidden` | Access Denied | User lacks the required role or organization/project membership. |
| `404 Not Found` | Resource Not Found | Target entity does not exist or is soft-deleted. |
| `409 Conflict` | Unique Key Violation | Duplicate registration or entity state conflict. |
| `500 Internal Error` | Server Exception | Unhandled internal exception; includes a correlation `TraceId` in logs. |

---

## 5. Common Query Parameters & Pagination

List endpoints support standard pagination via the `QueryParameters` model:

| Parameter | Type | Default | Constraints | Description |
|---|---|:---:|---|---|
| `page` | `integer` | `1` | `min: 1`, `max: 1000000` | The 1-based page index. |
| `pageSize` | `integer` | `20` | `min: 1`, `max: 100` | Number of items per page. |

**Example:**
```http
GET /api/projects?page=2&pageSize=15 HTTP/1.1
Authorization: Bearer <token>
```

---

## 6. API Endpoints Reference

---

### 1. Authentication Module (`/api/auth`)

Manage user registration, authentication, role claims inspection, and policy verification.

#### `POST /api/auth/register`
Creates a new user account under an organization. Default role assigned is `Client`.

- **Authentication:** None (Public)
- **Request Headers:** `Content-Type: application/json`
- **Request Body (`RegisterRequest`):**
  | Field | Type | Required | Constraints | Description |
  |---|---|:---:|---|---|
  | `fullName` | `string` | **Yes** | Max 200 chars | User's full name. |
  | `email` | `string` | **Yes** | Max 256 chars, Valid Email | Unique corporate/work email. |
  | `password` | `string` | **Yes** | Min 8 chars, uppercase, lowercase, digit, special char | Account security password. |
  | `phone` | `string` | No | Valid phone string | Optional contact number. |
  | `organizationId` | `integer` | **Yes** | `> 0` | ID of the organization to join. |

```json
// Request Sample
{
  "fullName": "Sarah Jenkins",
  "email": "sarah.jenkins@acmecorp.com",
  "password": "SecurePassword123!",
  "phone": "+1-555-0199",
  "organizationId": 1
}
```

```json
// Response Sample (200 OK)
{
  "success": true,
  "message": "Success",
  "data": {
    "userId": 14,
    "email": "sarah.jenkins@acmecorp.com",
    "fullName": "Sarah Jenkins",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresAt": "2026-09-30T10:15:30+00:00",
    "roles": [
      "Client"
    ]
  },
  "errors": null
}
```

---

#### `POST /api/auth/login`
Authenticates existing credentials and returns a signed JWT access token.

- **Authentication:** None (Public)
- **Request Body (`LoginRequest`):**
  | Field | Type | Required | Description |
  |---|---|:---:|---|
  | `email` | `string` | **Yes** | Registered email. |
  | `password` | `string` | **Yes** | Password. |

```json
// Request Sample
{
  "email": "sarah.jenkins@acmecorp.com",
  "password": "SecurePassword123!"
}
```

```json
// Response Sample (200 OK)
{
  "success": true,
  "message": "Success",
  "data": {
    "userId": 14,
    "email": "sarah.jenkins@acmecorp.com",
    "fullName": "Sarah Jenkins",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresAt": "2026-09-30T10:15:30+00:00",
    "roles": [
      "ProjectManager"
    ]
  },
  "errors": null
}
```

---

#### `GET /api/auth/me`
Fetches token identity claims for the currently authenticated caller.

- **Authentication:** Bearer Token
- **Response Sample (200 OK):**
```json
{
  "userId": "14",
  "email": "sarah.jenkins@acmecorp.com",
  "user": "sarah.jenkins@acmecorp.com",
  "roles": [
    "ProjectManager"
  ]
}
```

---

#### RBAC Verification Endpoints
Test access guards for specific roles. Returns `200 OK` on authorization success, `401 Unauthorized` if unauthenticated, and `403 Forbidden` if role is insufficient.

- `GET /api/auth/project-manager-only` (Requires `ProjectManager`)
- `GET /api/auth/team-leader-only` (Requires `TeamLeader`)
- `GET /api/auth/team-member-only` (Requires `TeamMember`)
- `GET /api/auth/client-only` (Requires `Client`)

---

### 2. User Profile Module (`/api/profile`)

Manage personal profile information, preferences, contact numbers, and UI defaults.

#### `GET /api/profile/me`
Retrieves the comprehensive profile details for the authenticated user.

- **Authentication:** Bearer Token
- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "userId": 14,
    "email": "sarah.jenkins@acmecorp.com",
    "fullName": "Sarah Jenkins",
    "jobTitle": "Lead Systems Architect",
    "role": "ProjectManager",
    "company": "Acme Global",
    "department": "Infrastructure",
    "phone": "+1-555-0199",
    "country": "United States",
    "city": "Seattle",
    "shortBio": "Overseeing microservice migration and distributed pipelines.",
    "language": "en-US",
    "defaultView": "Projects",
    "notificationsEnabled": true,
    "avatarUrl": "/uploads/avatars/u14.png"
  },
  "errors": null
}
```

---

#### `PUT /api/profile/me`
Updates profile settings for the authenticated user.

- **Authentication:** Bearer Token
- **Request Body (`UpdateProfileRequest`):**
  | Field | Type | Required | Constraints | Description |
  |---|---|:---:|---|---|
  | `fullName` | `string` | **Yes** | Max 200 chars | User's full display name. |
  | `jobTitle` | `string` | No | Max 100 chars | Corporate job title. |
  | `company` | `string` | No | Max 200 chars | Company name. |
  | `department` | `string` | No | Max 100 chars | Division or department. |
  | `phone` | `string` | No | Max 30 chars | Phone number. |
  | `country` | `string` | No | Max 100 chars | Country of residence. |
  | `city` | `string` | No | Max 100 chars | City of residence. |
  | `shortBio` | `string` | No | Max 1000 chars | Personal biography summary. |
  | `language` | `string` | No | Max 50 chars | Language locale code (e.g. `en-US`, `ar-SA`). |
  | `defaultView` | `string` | No | Max 50 chars | Initial screen (`Projects`, `Tasks`, `Dashboard`). |
  | `notificationsEnabled` | `boolean` | **Yes** | - | Toggle for receiving notifications. |

```json
// Request Sample
{
  "fullName": "Sarah Jenkins",
  "jobTitle": "Senior Technical Director",
  "company": "Acme Global",
  "department": "Engineering",
  "phone": "+1-555-0199",
  "country": "United States",
  "city": "Seattle",
  "shortBio": "Driving infrastructure scale and predictive operations.",
  "language": "en-US",
  "defaultView": "Dashboard",
  "notificationsEnabled": true
}
```

---

### 3. Projects Management Module (`/api/projects`)

Core resource controller for creating, updating, paginating, and attaching media to projects.

#### `GET /api/projects`
Retrieves a paginated list of projects accessible to the authenticated caller within their organization.

- **Authentication:** Bearer Token
- **Query Parameters:** `page` (default 1), `pageSize` (default 20)
- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "id": 101,
      "organizationId": 1,
      "ownerId": 14,
      "name": "Cloud Native Modernization",
      "description": "Migrating monolith workload to microservices on Kubernetes.",
      "workspaceUrl": "https://workspace.scaleflow.io/acme/proj-101",
      "progress": 45,
      "isAtRisk": false,
      "imageUrl": "/uploads/projects/a9f24c08e5e7.png",
      "status": 2,
      "priority": 3,
      "budget": 125000.00,
      "startDate": "2026-09-01T00:00:00+00:00",
      "endDate": "2026-12-31T00:00:00+00:00",
      "createdAt": "2026-09-15T08:30:00+00:00",
      "updatedAt": "2026-09-22T14:20:00+00:00"
    }
  ],
  "errors": null
}
```

---

#### `GET /api/projects/{id}`
Retrieves complete details for a single project by identifier.

- **Authentication:** Bearer Token
- **Path Parameters:** `id` (`integer`, required)
- **Status Codes:** `200 OK`, `401 Unauthorized`, `404 Not Found`

---

#### `POST /api/projects`
Creates a new project. The authenticated user is automatically designated as the project `Owner` and added as an active member.

- **Authentication:** Bearer Token
- **Request Body (`ProjectRequest`):**
  | Field | Type | Required | Constraints | Description |
  |---|---|:---:|---|---|
  | `name` | `string` | **Yes** | Max 200 chars | Project title. |
  | `description` | `string` | No | Max 4000 chars | Full scope description. |
  | `workspaceUrl` | `string` | No | URL | Collaboration / repository link. |
  | `progress` | `integer` | No | 0 - 100 | Manual completion percentage. |
  | `isAtRisk` | `boolean` | No | default `false` | Manual risk flag override. |
  | `status` | `integer (Enum)` | **Yes** | 0 to 6 (See Enums) | `0:Draft`, `1:Planning`, `2:Active`, `3:OnHold`, `4:Completed`, `5:Cancelled`, `6:Archived` |
  | `priority` | `integer (Enum)` | **Yes** | 1 to 4 (See Enums) | `1:Low`, `2:Medium`, `3:High`, `4:Critical` |
  | `budget` | `decimal` | No | `0 <= budget <= 99999999999999.9999` | Approved monetary budget. |
  | `startDate` | `datetime (ISO8601)` | No | - | Scheduled kick-off date. |
  | `endDate` | `datetime (ISO8601)` | No | `>= startDate` | Expected delivery date. |
  | `memberUserIds` | `array<integer>` | No | Valid user IDs | Initial team members to invite. |

```json
// Request Sample
{
  "name": "ScaleFlow Mobile 2.0",
  "description": "Revamping Flutter UI with offline cache and real-time notifications.",
  "workspaceUrl": "https://github.com/org/scaleflow-flutter",
  "progress": 10,
  "isAtRisk": false,
  "status": 2,
  "priority": 3,
  "budget": 75000.00,
  "startDate": "2026-10-01T00:00:00+00:00",
  "endDate": "2027-02-28T00:00:00+00:00",
  "memberUserIds": [14, 22, 35]
}
```

```json
// Response Sample (201 Created)
{
  "success": true,
  "message": "Project created.",
  "data": {
    "id": 102,
    "organizationId": 1,
    "ownerId": 14,
    "name": "ScaleFlow Mobile 2.0",
    "description": "Revamping Flutter UI with offline cache and real-time notifications.",
    "workspaceUrl": "https://github.com/org/scaleflow-flutter",
    "progress": 10,
    "isAtRisk": false,
    "imageUrl": null,
    "status": 2,
    "priority": 3,
    "budget": 75000.00,
    "startDate": "2026-10-01T00:00:00+00:00",
    "endDate": "2027-02-28T00:00:00+00:00",
    "createdAt": "2026-09-23T10:00:00+00:00",
    "updatedAt": null
  },
  "errors": null
}
```

---

#### `PUT /api/projects/{id}`
Updates details of an existing project. Automatically broadcasts `ProjectUpdated` to all clients in the project's SignalR room.

- **Authentication:** Bearer Token
- **Path Parameters:** `id` (`integer`, required)
- **Request Body:** Same as `ProjectRequest`.
- **Response:** `200 OK` with updated `ProjectResponse`.

---

#### `POST /api/projects/{id}/image`
Uploads a cover or banner image for the project. Automatically cleans up any previously uploaded image.

- **Authentication:** Bearer Token (Must be project Owner)
- **Content-Type:** `multipart/form-data`
- **Max File Size:** `5 MB`
- **Supported Formats:** JPG, JPEG, PNG, GIF, BMP, TIFF, ICO, AVIF, HEIC/HEIF.
- > [!WARNING]
  > WEBP images (`.webp` or `image/webp`) are explicitly rejected by policy.
- **Form Data Field:** `image` (`file`, required)
- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Project image uploaded.",
  "data": {
    "projectId": 102,
    "imageUrl": "/uploads/projects/3b994502d9c148ad8523c91e3e7f41ba.png",
    "fileName": "3b994502d9c148ad8523c91e3e7f41ba.png",
    "contentType": "image/png",
    "size": 184520
  },
  "errors": null
}
```

---

#### `DELETE /api/projects/{id}`
Performs a soft delete of the project. Restricts execution strictly to the Project Owner. Emits a `ProjectDeleted` real-time event.

- **Authentication:** Bearer Token (Project Owner only)
- **Status Codes:** `200 OK`, `403 Forbidden`, `404 Not Found`

---

### 4. Project Members Module (`/api/projects/{projectId}/members`)

Manage collaborator access, billing rates, custom roles, and blocking within a project.

#### `GET /api/projects/{projectId}/members`
Lists all members in the specified project.

- **Authentication:** Bearer Token (Active project member or owner)
- **Query Parameters:** `page`, `pageSize`
- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "id": 401,
      "projectId": 101,
      "userId": 22,
      "fullName": "Alex Mercer",
      "avatarUrl": "/uploads/avatars/u22.png",
      "jobTitle": "Senior Frontend Developer",
      "isActive": true,
      "isBlocked": false,
      "hourlyRate": 65.00,
      "roleOverride": "Lead Flutter Engineer",
      "joinedAt": "2026-09-16T12:00:00+00:00"
    }
  ],
  "errors": null
}
```

---

#### `POST /api/projects/{projectId}/members`
Adds a registered user from the organization to the project.

- **Authentication:** Bearer Token
- **Request Body (`AddProjectMemberRequest`):**
  | Field | Type | Required | Constraints | Description |
  |---|---|:---:|---|---|
  | `userId` | `integer` | **Yes** | `> 0` | ID of the organization user to add. |
  | `hourlyRate` | `decimal` | No | `>= 0` | Project-specific billing rate. |
  | `roleOverride` | `string` | No | Max 100 chars | Display title within this project. |

---

#### `PUT /api/projects/{projectId}/members/{userId}`
Updates member settings (block status, rate, title).

- **Authentication:** Bearer Token
- **Request Body (`UpdateProjectMemberRequest`):**
  | Field | Type | Required | Description |
  |---|---|:---:|---|
  | `isBlocked` | `boolean` | **Yes** | Temporarily suspend project access without removing member history. |
  | `hourlyRate` | `decimal` | No | Updated hourly billing rate. |
  | `roleOverride` | `string` | No | Updated custom title. |

---

#### `DELETE /api/projects/{projectId}/members/{userId}`
Removes a member from the project.

- **Authentication:** Bearer Token
- **Response:** `200 OK` (`ApiResponse<object>`).

---

### 5. Tasks Module (`/api/projects/{projectId}/tasks`)

Full CRUD capabilities for tasks, status pipelines, priority levels, and hours estimation.

#### `GET /api/projects/{projectId}/tasks`
Lists all tasks in the project with pagination.

- **Authentication:** Bearer Token
- **Path Parameters:** `projectId` (`integer`, required)
- **Query Parameters:** `page`, `pageSize`
- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "id": 501,
      "projectId": 101,
      "title": "Configure Identity JWT Claims",
      "description": "Ensure roles and organization ID are encoded into token payload.",
      "status": 5,
      "priority": 4,
      "type": 3,
      "plannedStart": "2026-09-18T09:00:00+00:00",
      "plannedEnd": "2026-09-20T17:00:00+00:00",
      "estimatedHours": 16.0,
      "completionPercent": 100,
      "createdBy": 14,
      "updatedBy": 14,
      "createdAt": "2026-09-17T11:00:00+00:00",
      "updatedAt": "2026-09-20T16:30:00+00:00"
    }
  ],
  "errors": null
}
```

---

#### `POST /api/projects/{projectId}/tasks`
Creates a new task. Emits a `TaskCreated` event via SignalR to the project group.

- **Authentication:** Bearer Token
- **Request Body (`TaskRequest`):**
  | Field | Type | Required | Constraints | Description |
  |---|---|:---:|---|---|
  | `title` | `string` | **Yes** | Max 200 chars | Task headline. |
  | `description` | `string` | No | Max 4000 chars | Acceptance criteria or description. |
  | `status` | `integer (Enum)` | **Yes** | 1 to 7 | `1:Backlog`, `2:Todo`, `3:InProgress`, `4:Review`, `5:Done`, `6:Blocked`, `7:Cancelled` |
  | `priority` | `integer (Enum)` | **Yes** | 1 to 4 | `1:Low`, `2:Medium`, `3:High`, `4:Critical` |
  | `type` | `integer (Enum)` | **Yes** | 1 to 4 | `1:Task`, `2:Bug`, `3:Feature`, `4:Research` |
  | `plannedStart` | `datetime` | No | - | Scheduled start timestamp. |
  | `plannedEnd` | `datetime` | No | `>= plannedStart` | Due timestamp. |
  | `estimatedHours` | `decimal` | No | `>= 0` | Estimated effort in hours. |
  | `completionPercent` | `integer` | No | 0 to 100 | Task completion percent. |

---

#### `PUT /api/projects/{projectId}/tasks/{id}`
Updates an existing task. Emits `TaskUpdated` to the project SignalR group.

- **Authentication:** Bearer Token
- **Path Parameters:** `projectId`, `id`
- **Request Body:** Same as `TaskRequest`.

---

#### `DELETE /api/projects/{projectId}/tasks/{id}`
Deletes a task and emits `TaskDeleted` to the project SignalR group.

- **Authentication:** Bearer Token
- **Response:** `200 OK` (`ApiResponse<object>`).

---

### 6. Task Dependencies Module (`/api/projects/{projectId}/tasks/{taskId}/dependencies`)

Define and manage dependency links between tasks (e.g. Finish-to-Start blocking chains).

#### `GET /api/projects/{projectId}/tasks/{taskId}/dependencies`
Lists all dependency relationships registered for a specific task.

- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "id": 88,
      "taskId": 502,
      "dependsOnTaskId": 501,
      "dependencyType": 1,
      "lagDays": 0,
      "notes": "Backend API must be finalized before Flutter client integration.",
      "createdAt": "2026-09-19T10:00:00+00:00"
    }
  ],
  "errors": null
}
```

---

#### `POST /api/projects/{projectId}/tasks/{taskId}/dependencies`
Adds a prerequisite dependency on another task in the same project.

- **Request Body (`TaskDependencyRequest`):**
  | Field | Type | Required | Constraints | Description |
  |---|---|:---:|---|---|
  | `dependsOnTaskId` | `integer` | **Yes** | `> 0` | The predecessor task that must satisfy condition. |
  | `dependencyType` | `integer (Enum)` | **Yes** | 1 to 4 | `1:FinishToStart`, `2:StartToStart`, `3:FinishToFinish`, `4:StartToFinish` |
  | `lagDays` | `integer` | No | - | Optional delay buffer in days. |
  | `notes` | `string` | No | Max 4000 chars | Reason for the dependency constraint. |

---

#### `DELETE /api/projects/{projectId}/tasks/{taskId}/dependencies/{id}`
Removes a task dependency rule.

- **Authentication:** Bearer Token
- **Response:** `200 OK` (`ApiResponse<object>`).

---

### 7. Teams Module (`/api/projects/{projectId}/teams`)

Organize project contributors into specialized functional squads (e.g. Frontend, DevOps, QA).

#### `GET /api/projects/{projectId}/teams`
Lists all teams inside the specified project.

- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "id": 12,
      "projectId": 101,
      "name": "Mobile Core Team",
      "description": "Engineers responsible for the Flutter mobile application.",
      "leadUserId": 22,
      "leadName": "Alex Mercer",
      "memberCount": 4,
      "createdAt": "2026-09-16T14:00:00+00:00",
      "updatedAt": null
    }
  ],
  "errors": null
}
```

---

#### `POST /api/projects/{projectId}/teams`
Creates a new team within the project.

- **Request Body (`TeamRequest`):**
  | Field | Type | Required | Constraints | Description |
  |---|---|:---:|---|---|
  | `name` | `string` | **Yes** | Max 200 chars | Unique team name. |
  | `description` | `string` | No | Max 4000 chars | Scope of responsibilities. |
  | `leadUserId` | `integer` | No | `> 0` | User ID of designated team lead. |

---

#### `GET /api/projects/{projectId}/teams/{teamId}/members`
Lists all members assigned to the specified team.

- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "id": 701,
      "teamId": 12,
      "userId": 22,
      "fullName": "Alex Mercer",
      "avatarUrl": "/uploads/avatars/u22.png",
      "jobTitle": "Senior Frontend Developer",
      "isActive": true,
      "roleInTeam": "Lead Architect",
      "joinedAt": "2026-09-17T09:30:00+00:00"
    }
  ],
  "errors": null
}
```

---

#### `POST /api/projects/{projectId}/teams/{teamId}/members`
Assigns an existing project member to a team.

- **Request Body (`AddTeamMemberRequest`):**
  | Field | Type | Required | Description |
  |---|---|:---:|---|
  | `userId` | `integer` | **Yes** | Member user ID. |
  | `roleInTeam` | `string` | No | Functional role (e.g. `UI Designer`, `QA Engineer`). |

---

#### `DELETE /api/projects/{projectId}/teams/{teamId}/members/{userId}`
Removes a member from the team.

---

### 8. Project Progress & Milestones Module (`/api/projects/{projectId}/progress`)

Provides real-time computed health, completion rates, and status distributions.

#### `GET /api/projects/{projectId}/progress`
Calculates cumulative task metrics and execution percentage.

- **Authentication:** Bearer Token
- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "projectId": 101,
    "totalTasks": 28,
    "completedTasks": 18,
    "inProgressTasks": 6,
    "blockedTasks": 2,
    "cancelledTasks": 2,
    "progressPercent": 64.29
  },
  "errors": null
}
```

---

### 9. Workload & Task Assignments Module (`/api/projects/{projectId}/workload`)

Track team capacity, identify overloaded individuals, and assign tasks with real-time sync.

#### `GET /api/projects/{projectId}/workload`
Provides a project-wide workload summary, average team utilization, and member distributions.

- **Authentication:** Bearer Token
- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "projectId": 101,
    "totalMembers": 5,
    "totalAssignedTasks": 22,
    "unassignedTasksCount": 4,
    "averageUtilization": 78.50,
    "overloadedMembersCount": 1,
    "underutilizedMembersCount": 0,
    "members": [
      {
        "userId": 22,
        "fullName": "Alex Mercer",
        "avatarUrl": "/uploads/avatars/u22.png",
        "jobTitle": "Lead Flutter Engineer",
        "assignedTasksCount": 7,
        "totalEstimatedHours": 42.0,
        "totalActualHours": 38.5,
        "completedTasksCount": 4,
        "inProgressTasksCount": 3,
        "overdueTasksCount": 1,
        "utilizationRatio": 105.00,
        "workloadStatus": "Overloaded"
      }
    ]
  },
  "errors": null
}
```

---

#### `GET /api/projects/{projectId}/workload/members/{userId}`
Fetches workload statistics for an individual team member within the project.

---

#### `POST /api/projects/{projectId}/workload/tasks/{taskId}/assignments`
Assigns a user to a task. Emits a `TaskAssignmentCreated` SignalR event.

- **Request Body (`AssignTaskRequest`):**
  | Field | Type | Required | Description |
  |---|---|:---:|---|
  | `assigneeUserId` | `integer` | **Yes** | ID of the user assigned to the task. |
  | `isPrimary` | `boolean` | No | Flag indicating if this user is the primary owner (`default: false`). |

---

#### `DELETE /api/projects/{projectId}/workload/tasks/{taskId}/assignments/{userId}`
Removes a task assignment and emits `TaskAssignmentRemoved` via SignalR.

---

### 10. Predictive AI Analytics Module (`/api/projects/{projectId}/ai`)

Provides AI-driven forecasting, risk factor scoring, delay probability calculations, and bottleneck detection.

> [!NOTE]
> If external ML inference microservices are offline or unavailable during development, the backend automatically activates fallback heuristics that compute deterministic scores from actual task data.

#### `POST /api/projects/{projectId}/ai/delay-prediction`
Computes the probability of project deadline slippage and estimates the days of delay.

- **Authentication:** Bearer Token
- **Request Body (`AiAnalysisRequest`):**
  | Field | Type | Default | Constraints | Description |
  |---|---|:---:|---|---|
  | `inputWindowDays` | `integer` | `30` | `1 to 365` | Historical lookback window in days. |

```json
// Response Sample (200 OK)
{
  "success": true,
  "message": "Success",
  "data": {
    "projectId": 101,
    "delayProbability": 0.42,
    "predictedDelayDays": 5,
    "confidence": 0.88,
    "explanation": "2 tasks on the critical path have unfinished prerequisites with overdue planned ends."
  },
  "errors": null
}
```

---

#### `POST /api/projects/{projectId}/ai/risk-analysis`
Analyzes composite project risk based on blocked tasks, overdue deadlines, and resource utilization.

- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "projectId": 101,
    "riskScore": 68.50,
    "confidence": 0.91,
    "explanation": "High concentration of unresolved tasks assigned to single overloaded lead developer."
  },
  "errors": null
}
```

---

#### `POST /api/projects/{projectId}/ai/bottleneck-detection`
Scans task dependencies to identify blockers that hold up multiple subsequent tasks.

- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "projectId": 101,
    "bottlenecks": [
      {
        "taskId": 501,
        "score": 0.85,
        "explanation": "Blocks 4 downstream frontend tasks; review has exceeded standard turnaround time."
      }
    ]
  },
  "errors": null
}
```

---

#### `POST /api/projects/{projectId}/ai/project-health`
Synthesizes a master health score combining velocity, risks, and deadline integrity.

- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "projectId": 101,
    "healthScore": 82.00,
    "riskCount": 3,
    "overdueTasksCount": 2,
    "confidence": 0.94,
    "explanation": "Project is in healthy condition with strong overall velocity, minor backlog in QA review."
  },
  "errors": null
}
```

---

### 11. Reports & Executive Summaries Module (`/api/projects/{projectId}/reports`)

Generate and retrieve structured executive summaries, risk reports, and team performance digests.

#### `GET /api/projects/{projectId}/reports`
Lists previously generated reports for the project.

- **Query Parameters:** `page`, `pageSize`

---

#### `GET /api/projects/{projectId}/reports/{id}`
Fetches the complete generated report including the raw JSON payload and summary markdown.

---

#### `POST /api/projects/{projectId}/reports/generate`
Generates a new report. Broadcasts `ReportGenerated` to the project's SignalR room upon completion.

- **Request Body (`GenerateReportRequest`):**
  | Field | Type | Required | Values / Constraints | Description |
  |---|---|:---:|---|---|
  | `title` | `string` | **Yes** | Max 200 chars | Report title. |
  | `reportType` | `string` | **Yes** | `Summary`, `Performance`, `Risk`, `FullAi` | Target analytical scope. |
  | `periodFrom` | `datetime` | No | ISO8601 | Start of evaluation interval. |
  | `periodTo` | `datetime` | No | `>= periodFrom` | End of evaluation interval. |

```json
// Request Sample
{
  "title": "Q3 Executive Sprint Health Digest",
  "reportType": "FullAi",
  "periodFrom": "2026-07-01T00:00:00+00:00",
  "periodTo": "2026-09-30T00:00:00+00:00"
}
```

```json
// Response Sample (201 Created)
{
  "success": true,
  "message": "Report generated successfully.",
  "data": {
    "id": 31,
    "projectId": 101,
    "title": "Q3 Executive Sprint Health Digest",
    "summaryText": "Executive Summary: Cloud Native Modernization is currently 64.3% complete with 18 of 28 tasks finalized. 2 blocked items require management unblocking.",
    "reportJson": "{\"Summary\":{...},\"Performance\":{...},\"Risks\":{...},\"AiRecommendations\":[\"Reassign QA review items to balance workload\"],\"ExecutiveSummary\":\"...\"}",
    "periodFrom": "2026-07-01T00:00:00+00:00",
    "periodTo": "2026-09-30T00:00:00+00:00",
    "createdBy": 14,
    "createdByName": "Sarah Jenkins",
    "createdAt": "2026-09-23T11:45:00+00:00"
  },
  "errors": null
}
```

---

### 12. Notifications Module (`/api/notifications`)

In-app alerts, unread counts, and status toggles for user activity.

#### `GET /api/notifications`
Retrieves user notifications with optional filtering for unread items only.

- **Authentication:** Bearer Token
- **Query Parameters:**
  - `page` (`integer`, default 1)
  - `pageSize` (`integer`, default 20)
  - `unreadOnly` (`boolean`, optional, e.g. `?unreadOnly=true`)
- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "id": 901,
      "recipientUserId": 14,
      "actorUserId": 22,
      "actorName": "Alex Mercer",
      "type": "TaskAssignment",
      "title": "New Task Assigned",
      "message": "Alex Mercer assigned you to task 'Review Redis Cache Integration'",
      "targetType": "Task",
      "targetId": 504,
      "projectId": 101,
      "readAt": null,
      "createdAt": "2026-09-23T12:10:00+00:00"
    }
  ],
  "errors": null
}
```

---

#### `GET /api/notifications/unread-count` & `/api/notifications/summary`
Returns counts of unread and total notifications.

```json
// Response Sample (200 OK)
{
  "success": true,
  "message": "Success",
  "data": {
    "unreadCount": 3,
    "totalCount": 24
  },
  "errors": null
}
```

---

#### `PUT /api/notifications/{id}/read`
Marks an individual notification as read.

---

#### `PUT /api/notifications/read-all`
Marks all notifications for the authenticated user as read.

- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "3 notifications marked as read.",
  "data": {
    "count": 3
  },
  "errors": null
}
```

---

### 13. Executive Dashboard Module (`/api/dashboard`)

High-level metrics aggregating project progress, deadlines, and workload for executive leadership.

#### `GET /api/dashboard/overview`
Retrieves a consolidated high-level snapshot across all projects the user is authorized to view.

- **Authentication:** Bearer Token
- **Response Sample (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "activeProjects": 4,
    "tasksDue": 12,
    "overdueTasks": 2,
    "atRiskProjects": 1,
    "completedTasks": 48,
    "totalTasks": 76,
    "overallProgress": 63.15,
    "onTrackProjects": 3,
    "projectPerformance": [
      {
        "projectId": 101,
        "projectName": "Cloud Native Modernization",
        "completionPercent": 64,
        "status": "Active"
      }
    ],
    "upcomingDeadlines": [
      {
        "taskId": 505,
        "taskTitle": "Deploy Ingress Controller",
        "projectId": 101,
        "projectName": "Cloud Native Modernization",
        "dueDate": "2026-09-25T18:00:00+00:00"
      }
    ],
    "teamWorkload": [
      {
        "userId": 22,
        "fullName": "Alex Mercer",
        "avatarUrl": "/uploads/avatars/u22.png",
        "workloadPercent": 105.00,
        "workloadStatus": "Overloaded"
      }
    ]
  },
  "errors": null
}
```

---

## 7. SignalR Real-Time WebSocket Hub (`/hubs/scaleflow`)

The ScaleFlow backend features a dedicated SignalR Hub that pushes live state updates to connected Flutter apps, web clients, and dashboards.

### Hub Connection & Authentication

- **Endpoint URL:** `wss://api.scaleflow.io/hubs/scaleflow` (or `http://localhost:5000/hubs/scaleflow`)
- **Authentication:** Since browser WebSockets do not support custom authorization headers, pass your JWT token in the query string:
  ```text
  /hubs/scaleflow?access_token=<YOUR_JWT_TOKEN>
  ```
- **Automatic User Room:** Upon connection, the hub automatically registers the connection to a private personal group: `user_{userId}`.

### Client Invocation Methods

Clients can invoke methods on the server through the SignalR connection:

| Method Name | Arguments | Behavior |
|---|---|---|
| `JoinProject` | `int projectId` | Verifies caller access to the project. If allowed, adds caller to group `project_{projectId}`. Throws `HubException("Unauthorized.")` or `HubException("Project not accessible.")` on failure. |
| `LeaveProject` | `int projectId` | Unsubscribes caller from group `project_{projectId}`. |

### Server Broadcast Events

The server dispatches the following events to subscribed client groups:

| Event Name | Target Group | Payload Schema | Description |
|---|---|---|---|
| `NotificationReceived` | `user_{userId}` | `NotificationResponse` | Dispatched immediately when a personal alert is generated. |
| `ProjectUpdated` | `project_{projectId}` | `ProjectResponse` | Emitted when project details, dates, or progress change. |
| `ProjectDeleted` | `project_{projectId}` | `{ "projectId": int }` | Emitted when a project is soft-deleted. |
| `TaskCreated` | `project_{projectId}` | `TaskResponse` | Broadcast when a new task is added to the project. |
| `TaskUpdated` | `project_{projectId}` | `TaskResponse` | Broadcast when task attributes or completion status change. |
| `TaskDeleted` | `project_{projectId}` | `{ "projectId": int, "taskId": int }` | Broadcast when a task is deleted. |
| `TaskAssignmentCreated` | `project_{projectId}` | `TaskAssignmentResponse` | Broadcast when a member is assigned to a task. |
| `TaskAssignmentRemoved` | `project_{projectId}` | `{ "taskId": int, "userId": int }` | Broadcast when an assignment is revoked. |
| `ReportGenerated` | `project_{projectId}` | `GeneratedReportResponse` | Broadcast when a report is completed. |

---

## 8. Enumerations & Data Reference

| Enum Name | Numeric Values & Descriptions |
|---|---|
| **`ProjectStatus`** | `0: Draft`, `1: Planning`, `2: Active`, `3: OnHold`, `4: Completed`, `5: Cancelled`, `6: Archived` |
| **`ProjectPriority`** | `1: Low`, `2: Medium`, `3: High`, `4: Critical` |
| **`TaskStatus`** | `1: Backlog`, `2: Todo`, `3: InProgress`, `4: Review`, `5: Done`, `6: Blocked`, `7: Cancelled` |
| **`TaskPriority`** | `1: Low`, `2: Medium`, `3: High`, `4: Critical` |
| **`TaskType`** | `1: Task`, `2: Bug`, `3: Feature`, `4: Research` |
| **`DependencyType`** | `1: FinishToStart`, `2: StartToStart`, `3: FinishToFinish`, `4: StartToFinish` |
| **`RoleScope`** | `0: Global`, `1: Project` |
| **`AiTriggerType`** | `1: Scheduled`, `2: Manual`, `3: Webhook` |
| **`AiRunStatus`** | `1: Pending`, `2: Running`, `3: Completed`, `4: Failed`, `5: Cancelled` |

---

## 9. Client Integration Examples

### Dart / Flutter (Dio / Http)

```dart
import 'package:dio/dio.dart';

class ScaleFlowApiClient {
  final Dio _dio;

  ScaleFlowApiClient({required String baseUrl, String? token})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ));

  /// Authenticate and retrieve token
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });

    final json = response.data;
    if (json['success'] == true) {
      return json['data'];
    } else {
      throw Exception(json['message'] ?? 'Authentication failed');
    }
  }

  /// Fetch accessible projects
  Future<List<dynamic>> getProjects({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get('/api/projects', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });

    return response.data['data'] as List<dynamic>;
  }
}
```

### TypeScript / Axios

```typescript
import axios from 'axios';

const api = axios.create({
  baseURL: 'https://api.scaleflow.io',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor to inject JWT token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('scaleflow_jwt');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Example: Fetch Dashboard Overview
export async function getDashboardOverview() {
  const response = await api.get('/api/dashboard/overview');
  if (response.data.success) {
    return response.data.data;
  }
  throw new Error(response.data.message);
}
```

---

*Documentation maintained by ScaleFlow Engineering.*  
*Version 1.0 (ASP.NET Core 8 / Flutter Compatible)*
