using System.Net.Http.Json;
using System.Text.Json.Serialization;

using ScaleFlow.DTOs;

namespace ScaleFlow.Services;

public class MlService : IMlService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<MlService> _logger;

    public MlService(
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<MlService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
    }

    // ============================================================
    // RISK
    // ============================================================

    public async Task<RiskAnalysisResponse> AnalyzeRisk(
        AiProjectInput request,
        CancellationToken cancellationToken)
    {
        var payload = BuildRiskPayload(request);

        _logger.LogInformation(
            "RISK PAYLOAD Project {ProjectId}: {Payload}",
            request.Project.Id,
            System.Text.Json.JsonSerializer.Serialize(payload));

        _logger.LogInformation(
            "Running risk analysis for ProjectId {ProjectId} with {TaskCount} tasks, {DependencyCount} dependencies and TeamSize {TeamSize}.",
            request.Project.Id,
            request.Tasks.Count,
            request.Dependencies.Count,
            request.TeamSize);

        var response = await _httpClient.PostAsJsonAsync(
            "/predict",
            payload,
            cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync(
                cancellationToken);

            throw new InvalidOperationException(
                $"Risk ML service returned {(int)response.StatusCode}: {errorBody}");
        }

        var prediction =
            await response.Content.ReadFromJsonAsync<RiskPredictionResponse>(
                cancellationToken: cancellationToken);

        if (prediction is null)
        {
            throw new InvalidOperationException(
                "Risk ML service returned an empty response.");
        }

        return new RiskAnalysisResponse(
            request.Project.Id,
            prediction.RiskScore,
            prediction.Confidence,
            BuildRiskExplanation(prediction));
    }

    private static Dictionary<string, object?> BuildRiskPayload(
        AiProjectInput request)
    {
        var project = request.Project;

        // ------------------------------------------------------------
        // REAL PROJECT / TASK DATA
        // ------------------------------------------------------------

        var taskCount = request.Tasks.Count;

        var completedTasks =
            request.Tasks.Count(
                task => (task.CompletionPercent ?? 0) >= 100);

        var blockedTasks =
            request.Tasks.Count(
                task => task.Status == Models.TaskStatus.Blocked);

        var highPriorityTasks =
            request.Tasks.Count(
                task => task.Priority == Models.TaskPriority.High);

        var overdueTasks =
            request.Tasks.Count(
                task =>
                    task.PlannedEnd.HasValue &&
                    task.PlannedEnd.Value < DateTimeOffset.UtcNow &&
                    (task.CompletionPercent ?? 0) < 100);

        var dependencyCount =
            request.Dependencies.Count;

        var durationDays =
            CalculateProjectDurationDays(request);

        var estimatedTimelineMonths =
            CalculateEstimatedTimelineMonths(request);

        var complexityScore =
            CalculateComplexityScore(
                taskCount,
                dependencyCount,
                blockedTasks,
                overdueTasks);

        var teamSize =
            Math.Max(1, request.TeamSize);

        var stakeholderCount =
            CalculateStakeholderCount(request);

        var projectPhase =
            GetProjectPhase(request);

        var priorityLevel =
            GetProjectPriority(request);

        var budgetUtilizationRate =
            CalculateBudgetUtilizationRate(request);

        var currentPhaseDurationMonths =
            CalculateCurrentPhaseDurationMonths(request);

        var projectStartMonth =
            GetProjectStartMonth(request);

        var progress =
            Math.Clamp(project.Progress, 0, 100);

        // ------------------------------------------------------------
        // DERIVED RISK INDICATORS
        // ------------------------------------------------------------

        var historicalRiskIncidents =
            blockedTasks +
            overdueTasks +
            (project.IsAtRisk ? 1 : 0);

        var schedulePressure =
            CalculateSchedulePressure(
                request,
                overdueTasks,
                progress);

        var resourceAvailability =
            CalculateResourceAvailability(
                teamSize,
                taskCount,
                blockedTasks);

        var integrationComplexity =
            Math.Max(1, dependencyCount);

        var crossFunctionalDependencies =
            Math.Max(0, dependencyCount);

        var previousDeliverySuccessRate =
            CalculatePreviousDeliverySuccessRate(
                request,
                completedTasks,
                taskCount,
                progress);

        var resourceContentionLevel =
            CalculateResourceContentionLevel(
                request,
                teamSize,
                taskCount,
                blockedTasks);

        // ------------------------------------------------------------
        // RISK MODEL
        //
        // The model expects exactly these 49 feature names.
        // ------------------------------------------------------------

        return new Dictionary<string, object?>
        {
            // --------------------------------------------------------
            // PROJECT INFORMATION
            // --------------------------------------------------------

            ["Project_Type"] =
                "IT",

            ["Team_Size"] =
                teamSize,

            ["Project_Budget_USD"] =
                project.Budget.HasValue
                    ? (double)Math.Max(
                        0m,
                        project.Budget.Value)
                    : 0.0,

            ["Estimated_Timeline_Months"] =
                estimatedTimelineMonths,

            ["Complexity_Score"] =
                complexityScore,

            ["Stakeholder_Count"] =
                stakeholderCount,

            // --------------------------------------------------------
            // PROJECT MANAGEMENT FEATURES
            // --------------------------------------------------------

            ["Methodology_Used"] =
                "Agile",

            ["Team_Experience_Level"] =
                "Mixed",

            ["Past_Similar_Projects"] =
                1,

            ["External_Dependencies_Count"] =
                dependencyCount,

            ["Change_Request_Frequency"] =
                0,

            ["Project_Phase"] =
                projectPhase,

            ["Requirement_Stability"] =
                "Stable",

            ["Team_Turnover_Rate"] =
                0.0,

            ["Vendor_Reliability_Score"] =
                0.8,

            // --------------------------------------------------------
            // RISK HISTORY
            // --------------------------------------------------------

            ["Historical_Risk_Incidents"] =
                historicalRiskIncidents,

            ["Communication_Frequency"] =
                CalculateCommunicationFrequency(request),

            ["Regulatory_Compliance_Level"] =
                "Low",

            ["Technology_Familiarity"] =
                "Familiar",

            ["Geographical_Distribution"] =
                teamSize > 1
                    ? 2
                    : 1,

            ["Stakeholder_Engagement_Level"] =
                "High",

            // --------------------------------------------------------
            // SCHEDULE / BUDGET
            // --------------------------------------------------------

            ["Schedule_Pressure"] =
                schedulePressure,

            ["Budget_Utilization_Rate"] =
                budgetUtilizationRate,

            ["Executive_Sponsorship"] =
                "Moderate",

            ["Funding_Source"] =
                "Internal",

            ["Market_Volatility"] =
                2.0,

            ["Integration_Complexity"] =
                integrationComplexity,

            ["Resource_Availability"] =
                resourceAvailability,

            // --------------------------------------------------------
            // PRIORITY / DEPENDENCIES
            // --------------------------------------------------------

            ["Priority_Level"] =
                priorityLevel,

            ["Organizational_Change_Frequency"] =
                1.0,

            ["Cross_Functional_Dependencies"] =
                crossFunctionalDependencies,

            ["Previous_Delivery_Success_Rate"] =
                previousDeliverySuccessRate,

            // --------------------------------------------------------
            // ORGANIZATION / TECHNICAL
            // --------------------------------------------------------

            ["Technical_Debt_Level"] =
                CalculateTechnicalDebtLevel(request),

            ["Project_Manager_Experience"] =
                "Mid-level PM",

            ["Org_Process_Maturity"] =
                "Defined",

            ["Data_Security_Requirements"] =
                "Medium",

            ["Key_Stakeholder_Availability"] =
                "Good",

            ["Tech_Environment_Stability"] =
                "Modern/Stable",

            ["Contract_Type"] =
                "Fixed-Price",

            ["Resource_Contention_Level"] =
                resourceContentionLevel,

            ["Industry_Volatility"] =
                "Moderate",

            ["Client_Experience_Level"] =
                "Regular",

            ["Change_Control_Maturity"] =
                "Formal",

            ["Risk_Management_Maturity"] =
                "Formal",

            ["Team_Colocation"] =
                "Hybrid",

            ["Documentation_Quality"] =
                "Good",

            // --------------------------------------------------------
            // TIME FEATURES
            // --------------------------------------------------------

            ["Project_Start_Month"] =
                projectStartMonth,

            ["Current_Phase_Duration_Months"] =
                currentPhaseDurationMonths,

            ["Seasonal_Risk_Factor"] =
                CalculateSeasonalRiskFactor(projectStartMonth)
        };
    }

    // ============================================================
    // RISK HELPERS
    // ============================================================

    private static int CalculateEstimatedTimelineMonths(
        AiProjectInput request)
    {
        var project = request.Project;

        if (project.StartDate.HasValue &&
            project.EndDate.HasValue &&
            project.EndDate.Value >= project.StartDate.Value)
        {
            var days =
                (project.EndDate.Value -
                 project.StartDate.Value).TotalDays;

            return Math.Max(
                1,
                (int)Math.Ceiling(days / 30.0));
        }

        var durationDays =
            CalculateProjectDurationDays(request);

        return Math.Max(
            1,
            (int)Math.Ceiling(durationDays / 30.0));
    }

    private static int CalculateComplexityScore(
        int taskCount,
        int dependencyCount,
        int blockedTasks,
        int overdueTasks)
    {
        var score =
            taskCount +
            (dependencyCount * 2) +
            (blockedTasks * 3) +
            (overdueTasks * 2);

        return Math.Clamp(
            score,
            1,
            100);
    }

    private static int CalculateStakeholderCount(
        AiProjectInput request)
    {
        return Math.Max(
            1,
            request.TeamSize);
    }

    private static double CalculateSchedulePressure(
        AiProjectInput request,
        int overdueTasks,
        int progress)
    {
        var pressure = 2.0;

        if (overdueTasks > 0)
        {
            pressure += 1.5;
        }

        var project = request.Project;

        if (project.EndDate.HasValue)
        {
            var remainingDays =
                (project.EndDate.Value -
                 DateTimeOffset.UtcNow).TotalDays;

            if (remainingDays < 0)
            {
                pressure += 1.5;
            }
            else if (remainingDays <= 7)
            {
                pressure += 1.0;
            }
            else if (remainingDays <= 30)
            {
                pressure += 0.5;
            }
        }

        if (progress < 30 && overdueTasks > 0)
        {
            pressure += 0.5;
        }

        return Math.Clamp(
            pressure,
            1.0,
            5.0);
    }

    private static double CalculateResourceAvailability(
        int teamSize,
        int taskCount,
        int blockedTasks)
    {
        if (teamSize <= 0)
        {
            return 0.3;
        }

        if (blockedTasks > 0)
        {
            return 0.6;
        }

        if (taskCount == 0)
        {
            return 0.9;
        }

        var tasksPerMember =
            (double)taskCount / teamSize;

        if (tasksPerMember >= 8)
        {
            return 0.5;
        }

        if (tasksPerMember >= 5)
        {
            return 0.7;
        }

        return 0.9;
    }

    private static double CalculatePreviousDeliverySuccessRate(
        AiProjectInput request,
        int completedTasks,
        int taskCount,
        int progress)
    {
        if (taskCount > 0)
        {
            return Math.Clamp(
                (double)completedTasks / taskCount,
                0.0,
                1.0);
        }

        return Math.Clamp(
            progress / 100.0,
            0.0,
            1.0);
    }

    private static string CalculateResourceContentionLevel(
        AiProjectInput request,
        int teamSize,
        int taskCount,
        int blockedTasks)
    {
        if (blockedTasks > 0)
        {
            return "Medium";
        }

        if (teamSize <= 1 && taskCount > 3)
        {
            return "High";
        }

        if (teamSize > 0 &&
            taskCount / (double)teamSize >= 6)
        {
            return "Medium";
        }

        return "Low";
    }

    private static double CalculateCommunicationFrequency(
        AiProjectInput request)
    {
        var teamSize =
            Math.Max(1, request.TeamSize);

        var dependencyCount =
            request.Dependencies.Count;

        var taskCount =
            request.Tasks.Count;

        var frequency =
            2.0 +
            Math.Min(4.0, teamSize / 2.0) +
            Math.Min(2.0, dependencyCount / 3.0) +
            (taskCount >= 10 ? 1.0 : 0.0);

        return Math.Clamp(
            frequency,
            1.0,
            10.0);
    }

    private static double CalculateTechnicalDebtLevel(
        AiProjectInput request)
    {
        var blockedTasks =
            request.Tasks.Count(
                task => task.Status == Models.TaskStatus.Blocked);

        var overdueTasks =
            request.Tasks.Count(
                task =>
                    task.PlannedEnd.HasValue &&
                    task.PlannedEnd.Value < DateTimeOffset.UtcNow &&
                    (task.CompletionPercent ?? 0) < 100);

        var dependencyCount =
            request.Dependencies.Count;

        var debt =
            1.0 +
            (blockedTasks * 0.75) +
            (overdueTasks * 0.5) +
            (dependencyCount * 0.15);

        return Math.Clamp(
            debt,
            1.0,
            5.0);
    }

    private static double CalculateSeasonalRiskFactor(
        int projectStartMonth)
    {
        return projectStartMonth switch
        {
            6 or 7 or 8 => 1.1,
            12 or 1 => 1.05,
            _ => 1.0
        };
    }

    private static string GetProjectPhase(
        AiProjectInput request)
    {
        var project = request.Project;

        var status =
            project.Status.ToString();

        if (status.Equals(
                "Planning",
                StringComparison.OrdinalIgnoreCase))
        {
            return "Planning";
        }

        if (status.Equals(
                "Execution",
                StringComparison.OrdinalIgnoreCase))
        {
            return "Execution";
        }

        if (status.Equals(
                "Monitoring",
                StringComparison.OrdinalIgnoreCase))
        {
            return "Monitoring";
        }

        if (status.Equals(
                "Closure",
                StringComparison.OrdinalIgnoreCase))
        {
            return "Closure";
        }

        if (request.Tasks.Count == 0)
        {
            return "Initiation";
        }

        var completed =
            request.Tasks.Count(
                task => (task.CompletionPercent ?? 0) >= 100);

        if (completed == request.Tasks.Count)
        {
            return "Closure";
        }

        if (completed == 0)
        {
            return "Planning";
        }

        if (request.Tasks.Any(
                task => task.Status == Models.TaskStatus.Blocked))
        {
            return "Monitoring";
        }

        return "Execution";
    }

    private static string GetProjectPriority(
        AiProjectInput request)
    {
        var projectPriority =
            request.Project.Priority.ToString();

        if (projectPriority.Equals(
                "Critical",
                StringComparison.OrdinalIgnoreCase))
        {
            return "Critical";
        }

        if (projectPriority.Equals(
                "High",
                StringComparison.OrdinalIgnoreCase))
        {
            return "High";
        }

        if (projectPriority.Equals(
                "Low",
                StringComparison.OrdinalIgnoreCase))
        {
            return "Low";
        }

        return "Medium";
    }

    private static double CalculateBudgetUtilizationRate(
        AiProjectInput request)
    {
        var progress =
            Math.Clamp(
                request.Project.Progress,
                0,
                100);

        return Math.Clamp(
            progress / 100.0,
            0.0,
            1.0);
    }

    private static int GetProjectStartMonth(
        AiProjectInput request)
    {
        if (request.Project.StartDate.HasValue)
        {
            return request.Project.StartDate.Value.Month;
        }

        var start =
            request.Tasks
                .Where(task => task.PlannedStart.HasValue)
                .Select(task => task.PlannedStart!.Value)
                .OrderBy(date => date)
                .FirstOrDefault();

        if (start == default)
        {
            return DateTime.UtcNow.Month;
        }

        return start.Month;
    }

    private static int CalculateCurrentPhaseDurationMonths(
        AiProjectInput request)
    {
        if (request.Project.StartDate.HasValue)
        {
            var days =
                (
                    DateTimeOffset.UtcNow -
                    request.Project.StartDate.Value
                ).TotalDays;

            return Math.Max(
                0,
                (int)Math.Floor(days / 30.0));
        }

        var durationDays =
            CalculateProjectDurationDays(request);

        return Math.Max(
            0,
            (int)Math.Floor(durationDays / 30.0));
    }

    private static string BuildRiskExplanation(
        RiskPredictionResponse prediction)
    {
        return
            $"Risk level: {prediction.RiskLevel}. " +
            $"Risk score: {prediction.RiskScore:0.00}/100. " +
            $"Model confidence: {prediction.Confidence:P0}.";
    }

    // ============================================================
    // BOTTLENECK
    // ============================================================

    public async Task<BottleneckDetectionResponse> DetectBottlenecks(
        AiProjectInput request,
        CancellationToken cancellationToken)
    {
        var baseUrl =
            _configuration["MlService:BottleneckBaseUrl"];

        if (string.IsNullOrWhiteSpace(baseUrl))
        {
            throw new InvalidOperationException(
                "MlService:BottleneckBaseUrl is not configured.");
        }

        using var client = new HttpClient
        {
            BaseAddress = new Uri(baseUrl),
            Timeout = TimeSpan.FromSeconds(30)
        };

        var bottlenecks =
            new List<BottleneckTaskResponse>();

        foreach (var task in request.Tasks)
        {
            var payload =
                BuildBottleneckPayload(request, task);

            var response = await client.PostAsJsonAsync(
                "/predict",
                payload,
                cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                var errorBody =
                    await response.Content.ReadAsStringAsync(
                        cancellationToken);

                throw new InvalidOperationException(
                    $"Bottleneck ML service returned " +
                    $"{(int)response.StatusCode}: {errorBody}");
            }

            var prediction =
                await response.Content.ReadFromJsonAsync<
                    BottleneckPredictionResponse>(
                    cancellationToken: cancellationToken);

            if (prediction is null)
            {
                continue;
            }

            if (prediction.IsBottleneck)
            {
                bottlenecks.Add(
                    new BottleneckTaskResponse(
                        task.Id,
                        prediction.BottleneckScore,
                        prediction.Label));
            }
        }

        return new BottleneckDetectionResponse(
            request.Project.Id,
            bottlenecks);
    }

    private static object BuildBottleneckPayload(
        AiProjectInput request,
        AiTaskInput task)
    {
        var cycleTimeHours =
            CalculateCycleTimeHours(task);

        var totalDays =
            CalculateTaskTotalDays(task);

        var issueAgeDays =
            CalculateIssueAgeDays(task);

        var totalTimeLoggedHours =
            (double)(task.ActualHours ?? 0);

        var worklogTotal =
            totalTimeLoggedHours;

        var worklogCount =
            task.ActualHours.HasValue ? 1 : 0;

        var transitionCount = 0;
        var reassignmentCount = 0;
        var reopenCount = 0;
        var priorityChanges = 0;
        var processOverhead = 0;
        var handoffComplexity = 0;

        var blockingIssues =
            request.Tasks.Count(
                t => t.Status == Models.TaskStatus.Blocked);

        var blockedByIssues =
            request.Dependencies.Count(
                d => d.TaskId == task.Id);

        var inwardLinks =
            request.Dependencies.Count(
                d => d.TaskId == task.Id);

        var outwardLinks =
            request.Dependencies.Count(
                d => d.DependsOnTaskId == task.Id);

        var dependencyComplexity =
            inwardLinks + outwardLinks;

        var coordinationComplexity =
            dependencyComplexity;

        var workSessions =
            worklogCount;

        var commentCount = 0;
        var communicationOverhead = 0;
        var collaborationIntensity = 0;
        var reworkIndicator = 0;
        var hasRework = 0;

        var isLongRunning =
            totalDays > 30 ? 1 : 0;

        var isStale =
            issueAgeDays > 30 ? 1 : 0;

        return new
        {
            issue_key = $"TASK-{task.Id}",
            cycle_time_hours = cycleTimeHours,
            total_days = totalDays,
            issue_age_days = issueAgeDays,
            total_time_logged_hours = totalTimeLoggedHours,
            worklog_total = worklogTotal,
            worklog_count = worklogCount,
            transition_count = transitionCount,
            reassignment_count = reassignmentCount,
            reopen_count = reopenCount,
            priority_changes = priorityChanges,
            process_overhead = processOverhead,
            handoff_complexity = handoffComplexity,
            blocking_issues = blockingIssues,
            blocked_by_issues = blockedByIssues,
            number_of_inward_links = inwardLinks,
            number_of_outward_links = outwardLinks,
            dependency_complexity = dependencyComplexity,
            coordination_complexity = coordinationComplexity,
            work_sessions = workSessions,
            comment_count = commentCount,
            communication_overhead = communicationOverhead,
            collaboration_intensity = collaborationIntensity,
            rework_indicator = reworkIndicator,
            has_rework = hasRework,
            is_long_running = isLongRunning,
            is_stale = isStale
        };
    }

    // ============================================================
    // DELAY
    // ============================================================

    public async Task<DelayPredictionResponse> PredictDelay(
        AiProjectInput request,
        CancellationToken cancellationToken)
    {
        var baseUrl =
            _configuration["MlService:DelayBaseUrl"];

        if (string.IsNullOrWhiteSpace(baseUrl))
        {
            throw new InvalidOperationException(
                "MlService:DelayBaseUrl is not configured.");
        }

        using var client = new HttpClient
        {
            BaseAddress = new Uri(baseUrl),
            Timeout = TimeSpan.FromSeconds(30)
        };

        if (request.Tasks.Count == 0)
        {
            return new DelayPredictionResponse(
                request.Project.Id,
                0m,
                0,
                0m,
                "No tasks are available for delay prediction.");
        }

        var predictions =
            new List<DelayTaskPrediction>();

        foreach (var task in request.Tasks)
        {
            var payload = new
            {
                task_id = task.Id,
                summary = task.Title,
                description = task.Title,
                labels = "development",
                priority = task.Priority.ToString(),
                created =
                    task.PlannedStart ??
                    DateTimeOffset.UtcNow
            };

            var response = await client.PostAsJsonAsync(
                "/predict",
                payload,
                cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                var errorBody =
                    await response.Content.ReadAsStringAsync(
                        cancellationToken);

                throw new InvalidOperationException(
                    $"Delay ML service returned " +
                    $"{(int)response.StatusCode}: {errorBody}");
            }

            var prediction =
                await response.Content.ReadFromJsonAsync<
                    DelayPredictionApiResponse>(
                    cancellationToken: cancellationToken);

            if (prediction is null)
            {
                continue;
            }

            predictions.Add(
                new DelayTaskPrediction(
                    task.Id,
                    prediction.PredictedClass,
                    prediction.DelayLevel,
                    prediction.Probabilities));
        }

        if (predictions.Count == 0)
        {
            return new DelayPredictionResponse(
                request.Project.Id,
                0m,
                0,
                0m,
                "No delay prediction was returned.");
        }

        var highestRisk =
            predictions
                .OrderByDescending(
                    prediction =>
                        GetDelayLevelValue(
                            prediction.DelayLevel))
                .First();

        var fastProbability =
            highestRisk.Probabilities?.Fast ?? 0m;

        var delayProbability =
            Math.Clamp(
                1m - fastProbability,
                0m,
                1m);

        var predictedDelayDays =
            GetPredictedDelayDays(
                highestRisk.PredictedClass);

        var confidence =
            GetDelayConfidence(
                highestRisk.Probabilities);

        var explanation =
            $"Highest predicted delay level: " +
            $"{highestRisk.DelayLevel}. " +
            $"Predicted class: " +
            $"{highestRisk.PredictedClass}. " +
            $"Model confidence: " +
            $"{confidence:P0}.";

        return new DelayPredictionResponse(
            request.Project.Id,
            decimal.Round(delayProbability, 4),
            predictedDelayDays,
            decimal.Round(confidence, 4),
            explanation);
    }

    // ============================================================
    // HEALTH
    // ============================================================

    public async Task<AiProjectHealthResponse> GetProjectHealth(
        AiProjectInput request,
        CancellationToken cancellationToken)
    {
        var baseUrl =
            _configuration["MlService:HealthBaseUrl"];

        if (string.IsNullOrWhiteSpace(baseUrl))
        {
            throw new InvalidOperationException(
                "MlService:HealthBaseUrl is not configured.");
        }

        using var client = new HttpClient
        {
            BaseAddress = new Uri(baseUrl),
            Timeout = TimeSpan.FromSeconds(30)
        };

        var payload =
            BuildHealthPayload(request);

        var response = await client.PostAsJsonAsync(
            "/predict",
            payload,
            cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var errorBody =
                await response.Content.ReadAsStringAsync(
                    cancellationToken);

            throw new InvalidOperationException(
                $"Health ML service returned " +
                $"{(int)response.StatusCode}: {errorBody}");
        }

        var prediction =
            await response.Content.ReadFromJsonAsync<
                HealthPredictionResponse>(
                cancellationToken: cancellationToken);

        if (prediction is null)
        {
            throw new InvalidOperationException(
                "Health ML service returned an empty response.");
        }

        var riskCount =
            request.Tasks.Count(
                task =>
                    task.Status ==
                    Models.TaskStatus.Blocked);

        var overdueTasksCount =
            request.Tasks.Count(
                task =>
                    task.PlannedEnd.HasValue &&
                    task.PlannedEnd.Value <
                        DateTimeOffset.UtcNow &&
                    (task.CompletionPercent ?? 0) < 100);

        var confidence =
            Math.Clamp(
                1m - prediction.FailureProbability,
                0m,
                1m);

        return new AiProjectHealthResponse(
            request.Project.Id,
            prediction.HealthScore,
            riskCount,
            overdueTasksCount,
            decimal.Round(confidence, 4),
            $"Project health status: " +
            $"{prediction.Status}. " +
            $"Health score: " +
            $"{prediction.HealthScore:0.00}/100. " +
            $"Failure probability: " +
            $"{prediction.FailureProbability:P0}.");
    }

    private static object BuildHealthPayload(
        AiProjectInput request)
    {
        var plannedHours =
            request.Tasks.Sum(
                task =>
                    (double)(task.EstimatedHours ?? 0));

        var taskCount =
            request.Tasks.Count;

        var taskPlannedHours =
            plannedHours;

        var containerTaskCount =
            request.Tasks.Count(
                task =>
                    task.EstimatedHours is null);

        var declarationCount =
            request.Tasks.Count(
                task =>
                    task.ActualHours.HasValue);

        var totalLoggedHours =
            request.Tasks.Sum(
                task =>
                    (double)(task.ActualHours ?? 0));

        var activeUsers =
            request.TeamSize;

        var activeDays =
            CalculateProjectDurationDays(request);

        if (activeDays <= 0)
        {
            activeDays = 1;
        }

        var avgLoggedHoursPerUser =
            activeUsers > 0
                ? totalLoggedHours / activeUsers
                : 0;

        var avgLoggedHoursPerDay =
            totalLoggedHours / activeDays;

        var avgLoggedHoursPerTask =
            taskCount > 0
                ? totalLoggedHours / taskCount
                : 0;

        return new
        {
            planned_hours = plannedHours,
            task_count = taskCount,
            task_planned_hours = taskPlannedHours,
            container_task_count = containerTaskCount,
            declaration_count = declarationCount,
            total_logged_hours = totalLoggedHours,
            active_users = activeUsers,
            active_days = activeDays,
            avg_logged_hours_per_user =
                avgLoggedHoursPerUser,
            avg_logged_hours_per_day =
                avgLoggedHoursPerDay,
            avg_logged_hours_per_task =
                avgLoggedHoursPerTask
        };
    }

    // ============================================================
    // GENERAL HELPERS
    // ============================================================

    private static int CalculateProjectDurationDays(
        AiProjectInput request)
    {
        if (request.Project.StartDate.HasValue &&
            request.Project.EndDate.HasValue &&
            request.Project.EndDate.Value >=
                request.Project.StartDate.Value)
        {
            var projectDays =
                (
                    request.Project.EndDate.Value -
                    request.Project.StartDate.Value
                ).TotalDays;

            return Math.Max(
                1,
                (int)Math.Ceiling(projectDays));
        }

        var starts =
            request.Tasks
                .Where(task =>
                    task.PlannedStart.HasValue)
                .Select(task =>
                    task.PlannedStart!.Value);

        var ends =
            request.Tasks
                .Where(task =>
                    task.PlannedEnd.HasValue)
                .Select(task =>
                    task.PlannedEnd!.Value);

        if (!starts.Any() || !ends.Any())
        {
            return 1;
        }

        var start =
            starts.Min();

        var end =
            ends.Max();

        var days =
            (end - start).TotalDays;

        return Math.Max(
            1,
            (int)Math.Ceiling(days));
    }

    private static double CalculateCycleTimeHours(
        AiTaskInput task)
    {
        if (task.ActualStart.HasValue &&
            task.ActualEnd.HasValue)
        {
            return Math.Max(
                0,
                (
                    task.ActualEnd.Value -
                    task.ActualStart.Value
                ).TotalHours);
        }

        if (task.PlannedStart.HasValue &&
            task.PlannedEnd.HasValue)
        {
            return Math.Max(
                0,
                (
                    task.PlannedEnd.Value -
                    task.PlannedStart.Value
                ).TotalHours);
        }

        return 0;
    }

    private static int CalculateTaskTotalDays(
        AiTaskInput task)
    {
        var hours =
            CalculateCycleTimeHours(task);

        return Math.Max(
            0,
            (int)Math.Ceiling(hours / 24));
    }

    private static int CalculateIssueAgeDays(
        AiTaskInput task)
    {
        var created =
            task.ActualStart ??
            task.PlannedStart;

        if (!created.HasValue)
        {
            return 0;
        }

        var age =
            DateTimeOffset.UtcNow -
            created.Value;

        return Math.Max(
            0,
            (int)Math.Floor(age.TotalDays));
    }

    private static int GetDelayLevelValue(
        string? delayLevel)
    {
        return delayLevel?.ToLowerInvariant() switch
        {
            "low" => 20,
            "medium" => 60,
            "high" => 90,
            _ => 0
        };
    }

    private static int GetPredictedDelayDays(
        string? predictedClass)
    {
        if (string.IsNullOrWhiteSpace(predictedClass))
        {
            return 0;
        }

        if (predictedClass.StartsWith(
            "Fast",
            StringComparison.OrdinalIgnoreCase))
        {
            return 30;
        }

        if (predictedClass.StartsWith(
            "Medium",
            StringComparison.OrdinalIgnoreCase))
        {
            return 365;
        }

        if (predictedClass.StartsWith(
            "Slow",
            StringComparison.OrdinalIgnoreCase))
        {
            return 366;
        }

        return 0;
    }

    private static decimal GetDelayConfidence(
        DelayProbabilities? probabilities)
    {
        if (probabilities is null)
        {
            return 0m;
        }

        return Math.Clamp(
            Math.Max(
                probabilities.Fast,
                Math.Max(
                    probabilities.Medium,
                    probabilities.Slow)),
            0m,
            1m);
    }

    // ============================================================
    // ML API RESPONSE MODELS
    // ============================================================

    private sealed record RiskPredictionResponse(
        [property: JsonPropertyName("risk_score")]
        decimal RiskScore,

        [property: JsonPropertyName("risk_level")]
        string RiskLevel,

        [property: JsonPropertyName("confidence")]
        decimal Confidence,

        [property: JsonPropertyName("probabilities")]
        Dictionary<string, decimal>? Probabilities);

    private sealed record BottleneckPredictionResponse(
        [property: JsonPropertyName("issue_key")]
        string? IssueKey,

        [property: JsonPropertyName("bottleneck_score")]
        decimal BottleneckScore,

        [property: JsonPropertyName("is_bottleneck")]
        bool IsBottleneck,

        [property: JsonPropertyName("label")]
        string? Label);

    private sealed record DelayPredictionApiResponse(
        [property: JsonPropertyName("task_id")]
        int TaskId,

        [property: JsonPropertyName("predicted_class")]
        string PredictedClass,

        [property: JsonPropertyName("delay_level")]
        string DelayLevel,

        [property: JsonPropertyName("probabilities")]
        DelayProbabilities? Probabilities);

    private sealed record DelayProbabilities(
        [property: JsonPropertyName("fast")]
        decimal Fast,

        [property: JsonPropertyName("medium")]
        decimal Medium,

        [property: JsonPropertyName("slow")]
        decimal Slow);

    private sealed record HealthPredictionResponse(
        [property: JsonPropertyName("health_score")]
        decimal HealthScore,

        [property: JsonPropertyName("status")]
        string Status,

        [property: JsonPropertyName("failure_probability")]
        decimal FailureProbability);

    private sealed record DelayTaskPrediction(
        int TaskId,
        string PredictedClass,
        string DelayLevel,
        DelayProbabilities? Probabilities);
}