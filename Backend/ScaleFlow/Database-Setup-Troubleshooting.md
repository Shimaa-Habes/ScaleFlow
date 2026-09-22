# Database Setup Troubleshooting

## Original problem

ScaleFlow was configured to connect to `(localdb)\\MSSQLLocalDB`, but the LocalDB runtime is not installed on this machine. The application and EF Core commands therefore failed with `Unable to locate a Local Database Runtime installation.`

## Root cause

Both `appsettings.json` and `appsettings.Development.json` overrode `ScaleFlowConnection` with the LocalDB instance. The installed SQL Server instance is SQL Server Express named `SQLEXPRESS`.

The application also used `EnsureCreatedAsync()` even though the project contains EF Core migrations. That bypasses the migrations history and can conflict with migration-based schema management. The existing migration additionally had SQL Server multiple-cascade-path conflicts. These were corrected by making project ownership, project membership, workload, team membership, task attachment, and task comment user relationships restrictive while preserving the intended project/task cascades.

## Configuration used

The active connection string is:

```text
Server=.\\SQLEXPRESS;Database=ScaleFlowDb;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true
```

The connection string key remains `ScaleFlowConnection`. No password or secret was added. No environment variable override for this key was present during verification.

## Changes made

- Updated `appsettings.json` and `appsettings.Development.json` to use `.`\\`SQLEXPRESS`.
- Changed startup database initialization from `EnsureCreatedAsync()` to `Database.MigrateAsync()`.
- Preserved the existing role initialization after migrations.
- Added explicit restrictive delete behavior for user relationships that otherwise created SQL Server multiple cascade paths.
- Updated the existing migration to match the corrected model. No migrations were deleted and the database was not reset.

## Verification commands and results

- `sqlcmd -S '.\\SQLEXPRESS' -E -Q "SELECT ..." -b` succeeded and reported `DESKTOP-KP0TRTK\\SQLEXPRESS`, instance `SQLEXPRESS`.
- `dotnet build` succeeded.
- `dotnet ef database update` succeeded. It created `ScaleFlowDb`, applied `20260917184655_ConfigureDecimalPrecision`, and inserted the migration history row.
- `sqlcmd -S '.\\SQLEXPRESS' -E -d ScaleFlowDb ...` confirmed the migration history row and four seeded roles.
- `dotnet run` succeeded. Startup reported `No migrations were applied. The database is already up to date.` and completed role initialization.
- `Invoke-WebRequest http://localhost:5233/swagger/index.html` returned HTTP 200.
- `dotnet run --launch-profile https` succeeded and listened on `https://localhost:7084` and `http://localhost:5233`.
- `curl.exe -k https://localhost:7084/swagger/index.html` returned HTTP 200.
- Final search found no active `localdb` or `MSSQLLocalDB` references. The only connection string uses `SQLEXPRESS`.

## Remaining limitations or manual steps

- SQL Server Express service `MSSQL$SQLEXPRESS` must remain installed and running.
- Windows Authentication requires the Windows account running the API or EF CLI to have access to SQL Server and `ScaleFlowDb`.
- The HTTPS endpoint was verified with certificate validation disabled for the local development certificate. The certificate is not trusted by the machine and may need to be trusted for normal browser/client use.
