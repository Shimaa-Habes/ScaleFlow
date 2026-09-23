# ScaleFlow Enterprise Platform

ScaleFlow is an enterprise-grade project management, resource allocation, and predictive AI platform built with **ASP.NET Core 8 Web API**, **SQL Server (EF Core)**, **SignalR WebSockets**, and a modern **Flutter** cross-platform client.

---

## 📚 API & Developer Documentation

The platform includes comprehensive, production-grade documentation:

- 📖 **[Master API Reference Guide (Markdown)](./API_DOCUMENTATION.md)**: Full REST & SignalR API documentation detailing authentication, envelope models, validation rules, error handling, endpoints, and client snippets.
- 📐 **[OpenAPI 3.0 Specification (YAML)](./docs/openapi.yaml)**: OpenAPI / Swagger 3.0 standard schema for importing into Swagger UI, Insomnia, or client SDK generators.
- 🚀 **[Postman Collection (v2.1.0)](./docs/scaleflow_postman_collection.json)**: Ready-to-import Postman workspace with pre-configured requests, environment variables, and automatic JWT token extraction on login.

---

## 🏗 System Architecture & Modules

```text
               +-----------------------------+
               | Flutter Client / Web App    |
               +--------------+--------------+
                              |
                     REST API | SignalR WSS
                              v
               +-----------------------------+
               | ASP.NET Core 8 Web API      |
               | - JWT Bearer & RBAC         |
               | - FluentValidation Pipeline |
               | - Predictive AI & ML Engine |
               +--------------+--------------+
                              |
                              v
               +-----------------------------+
               | Microsoft SQL Server        |
               +-----------------------------+
```

### Core API Modules
1. **Authentication & RBAC (`/api/auth`)**: JWT-based login, registration, and role policies (`ProjectManager`, `TeamLeader`, `TeamMember`, `Client`).
2. **User Profile (`/api/profile`)**: User information, avatar, locale, and UI preferences.
3. **Projects (`/api/projects`)**: Project lifecycle, budget, timeline, and image upload.
4. **Project Members (`/api/projects/{id}/members`)**: Multi-tenant team assignment, billing rates, and block statuses.
5. **Tasks & Dependencies (`/api/projects/{id}/tasks`)**: Sprint work items, priority scoring, completion percentages, and Finish-to-Start dependencies.
6. **Teams (`/api/projects/{id}/teams`)**: Squad organization and leadership hierarchy.
7. **Workload & Balancing (`/api/projects/{id}/workload`)**: Real-time capacity utilization, overloaded member detection, and assignments.
8. **Predictive AI Analytics (`/api/projects/{id}/ai`)**: Delay forecasting, risk modeling, bottleneck detection, and composite health scores.
9. **Executive Reports (`/api/projects/{id}/reports`)**: AI-generated performance, risk, and sprint digests.
10. **In-App Notifications (`/api/notifications`)**: Read tracking and live alert delivery.
11. **Executive Dashboard (`/api/dashboard`)**: High-level KPIs and upcoming deadline tracking.
12. **SignalR Real-Time Hub (`/hubs/scaleflow`)**: Push updates for project status, tasks, workload, and alerts.

---

## 🚀 Getting Started

### 1. Backend API (.NET 8)
```bash
cd Backend/ScaleFlow
dotnet restore
dotnet build
dotnet run
```
Swagger UI will be accessible locally at `http://localhost:5000/swagger`.

### 2. Flutter Mobile Application
```bash
cd Flutter
flutter pub get
flutter run
```

---

*Documentation maintained by ScaleFlow Engineering.*
