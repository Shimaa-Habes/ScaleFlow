# Decimal Precision Fix

## Root Cause

The entity model contained nullable `decimal` properties without explicit SQL Server precision and scale. EF Core therefore inferred the provider default and reported decimal precision warnings during model validation. The project had no existing EF Core migrations.

All decimal properties in the project were inspected. The model contains 16 decimal properties, and each is configured in `ScaleFlowDbContext.OnModelCreating` with `.HasPrecision(precision, scale)`.

## Precision Decisions

| Entity | Property | SQL Server type | Rationale |
|---|---|---|---|
| `AiPrediction` | `RiskScore` | `decimal(5,4)` | Normalized score assumption: 0 to 1 with four decimal places. |
| `AiPrediction` | `DelayProbability` | `decimal(5,4)` | Probability assumption: 0 to 1 with four decimal places. |
| `AiPrediction` | `Confidence` | `decimal(5,4)` | Confidence assumption: 0 to 1 with four decimal places. |
| `Project` | `Budget` | `decimal(19,4)` | Monetary value with four fractional digits and a large maximum range. |
| `ProjectHealthSnapshot` | `HealthScore` | `decimal(5,2)` | Percentage-like score assumption: 0 to 100 with two decimal places. |
| `ProjectHealthSnapshot` | `Velocity` | `decimal(12,2)` | Metric that may grow beyond a ratio and needs fractional units. |
| `ProjectHealthSnapshot` | `Throughput` | `decimal(12,2)` | Metric that may grow beyond a ratio and needs fractional units. |
| `ProjectHealthSnapshot` | `OpenRiskRatio` | `decimal(5,4)` | Normalized ratio assumption: 0 to 1 with four decimal places. |
| `ProjectHealthSnapshot` | `TeamUtilizationAvg` | `decimal(5,4)` | Normalized utilization assumption: 0 to 1 with four decimal places. |
| `ProjectMember` | `HourlyRate` | `decimal(19,4)` | Monetary rate with four fractional digits and a large maximum range. |
| `ProjectTask` | `EstimatedHours` | `decimal(10,2)` | Fractional hours with two decimal places and room for long-running tasks. |
| `ProjectTask` | `ActualHours` | `decimal(10,2)` | Fractional hours with two decimal places and room for long-running tasks. |
| `WorkloadSnapshot` | `PlannedHours` | `decimal(10,2)` | Fractional hours with two decimal places and room for planning periods. |
| `WorkloadSnapshot` | `ActualHours` | `decimal(10,2)` | Fractional hours with two decimal places and room for reporting periods. |
| `WorkloadSnapshot` | `UtilizationRatio` | `decimal(5,4)` | Normalized ratio assumption: 0 to 1 with four decimal places. |
| `WorkloadSnapshot` | `OverloadScore` | `decimal(8,4)` | Score may exceed 1 when workload is above capacity; four decimal places retain detail. |

The ranges are code-based assumptions because the entities do not currently include validation attributes, DTO validation rules, or domain documentation defining maximum values. These mappings should be revisited if product requirements establish different ranges.

## Migration

Created migration: `ConfigureDecimalPrecision`.

The migration is an initial schema migration because no migrations existed in the repository. It was not applied locally: the configured `(localdb)\\MSSQLLocalDB` instance is unavailable and the LocalDB runtime is not installed. After SQL Server LocalDB or another configured SQL Server is available, run:

```text
dotnet ef database update
```

## Validation

Commands run from the `ScaleFlow` project directory:

```text
dotnet build .\\ScaleFlow.csproj --no-restore
dotnet ef migrations list
dotnet ef migrations add ConfigureDecimalPrecision
dotnet ef database update
dotnet run --no-build --no-restore
```

Results:

- `dotnet build`: passed.
- Initial `dotnet ef migrations list`: passed with no migrations found; it reported the unavailable LocalDB runtime.
- `dotnet ef migrations add ConfigureDecimalPrecision`: passed and generated the migration plus model snapshot.
- `dotnet ef database update`: could not connect because the LocalDB runtime/instance is unavailable.
- `dotnet run`: loaded launch settings and then remained blocked during the existing startup `EnsureCreatedAsync` database connection. No application listening state could be verified in this environment.
- No EF decimal precision warnings remain in the generated model metadata for the 16 configured properties. Runtime database warnings could not be rechecked past database initialization because LocalDB is unavailable.
- Authentication, JWT, Identity, RBAC, and controller code were not changed.

## Remaining Issues

Install/start SQL Server LocalDB or provide an accessible SQL Server connection, then run `dotnet ef database update` and `dotnet run` again. The database update is the only unresolved deployment step from this environment.