"""
ScaleFlow AI/ML Module - Feature & Target Definitions
------------------------------------------------------
Input and target definitions for the four ML problems described in the
ScaleFlow AI/ML Model Approach document. Column names follow the input
features listed in that document (Sections 4-7) so this file is the
single source of truth: if a column name changes once the real dataset
arrives, it only needs to be updated here.
"""

# =======================================================================
# 1. TASK DELAY PREDICTION  (Model Approach, Section 4)
# =======================================================================
# ML type   : Binary Classification
# Target    : is_delayed -> 1 if actual finish date is after the planned
#             due date, 0 otherwise.
# Model     : Random Forest Classifier

DELAY_NUMERIC_FEATURES = [
    "progress_percentage",
    "estimated_duration",
    "days_until_deadline",
    "task_age",
    "dependency_count",
    "delayed_dependency_count",
    "workload_ratio",
    "active_tasks_count",
    "historical_delay_rate",
    "average_completion_time",
]

DELAY_CATEGORICAL_FEATURES = [
    "task_status",
    "priority",
    "blocked_status",
]

DELAY_TARGET = "is_delayed"  # 1 = delayed, 0 = on-time

DELAY_FEATURES = DELAY_NUMERIC_FEATURES + DELAY_CATEGORICAL_FEATURES

# Fields used ONLY to construct the is_delayed label after the fact.
# Section 10 ("Avoiding Data Leakage") of the Model Approach document
# states these must never be used as input features while a task is
# still open, since they would not be available at prediction time.
DELAY_LEAKAGE_FIELDS = [
    "completed_date",
    "actual_duration",
    "final_delay_days",
]

# =======================================================================
# 2. RISK ANALYSIS  (Model Approach, Section 5)
# =======================================================================
# ML type   : Classification (initial approach)
# Target    : risk_level (Low / Medium / High) — or risk_score if the
#             data requirements document provides a continuous target
#             instead of discrete classes.
# Model     : Random Forest Classifier
#
# Input features are grouped exactly as in the Model Approach document:
# Schedule, Progress, Dependencies, Resources, History.

RISK_SCHEDULE_FEATURES = [
    "delay_probability",       # output of the Task Delay Prediction model
    "overdue_task_ratio",
]
RISK_SCHEDULE_CATEGORICAL = [
    "milestone_status",
]

RISK_PROGRESS_FEATURES = [
    "project_progress",
    "progress_variance",
]

RISK_DEPENDENCY_FEATURES = [
    "blocked_tasks",
    "delayed_dependency_count",
]

RISK_RESOURCE_FEATURES = [
    "workload_ratio",
    "team_size",
    "overloaded_members",
]

RISK_HISTORY_FEATURES = [
    "historical_project_delay_rate",
]
RISK_HISTORY_CATEGORICAL = [
    "previous_risk_outcomes",
]

RISK_NUMERIC_FEATURES = (
    RISK_SCHEDULE_FEATURES
    + RISK_PROGRESS_FEATURES
    + RISK_DEPENDENCY_FEATURES
    + RISK_RESOURCE_FEATURES
    + RISK_HISTORY_FEATURES
)

RISK_CATEGORICAL_FEATURES = RISK_SCHEDULE_CATEGORICAL + RISK_HISTORY_CATEGORICAL

RISK_TARGET = "risk_level"  # "low" / "medium" / "high"

# Alternative continuous target, per the Model Approach document
# ("The AI/ML Data Requirements document explicitly allows either
# risk_level or risk_score as the target.")
RISK_TARGET_REGRESSION = "risk_score"  # 0-100

RISK_FEATURES = RISK_NUMERIC_FEATURES + RISK_CATEGORICAL_FEATURES

# =======================================================================
# 3. BOTTLENECK DETECTION  (Model Approach, Section 6)
# =======================================================================
# ML type   : Anomaly Detection (unsupervised — no labeled data exists yet)
# Model     : Isolation Forest
# Output    : Bottleneck / anomaly score (no ground-truth target column)

BOTTLENECK_NUMERIC_FEATURES = [
    "task_duration",
    "completion_velocity",
    "blocked_duration",
    "dependency_count",
    "delayed_dependency_count",
    "workload_ratio",
    "num_dependent_tasks",
    "historical_completion_time",
]

# No categorical features and no target column: Isolation Forest is
# unsupervised, consistent with Section 6 of the Model Approach document.
BOTTLENECK_CATEGORICAL_FEATURES: list = []
BOTTLENECK_TARGET = None

BOTTLENECK_FEATURES = BOTTLENECK_NUMERIC_FEATURES + BOTTLENECK_CATEGORICAL_FEATURES

# =======================================================================
# 4. PROJECT PERFORMANCE / HEALTH ANALYSIS  (Model Approach, Section 7)
# =======================================================================
# ML type   : Regression
# Model     : Random Forest Regressor
# Status    : Phase 2 — deferred until a reliable numerical health
#             target is available. Structure is prepared here so
#             training can start as soon as that target exists.

PERFORMANCE_NUMERIC_FEATURES = [
    "project_progress_percentage",
    "overdue_task_count",
    "completed_task_count",
    "blocked_task_count",
    "workload_ratio",
    "team_size",
    "historical_delay_rate",
    "progress_variance",
    "completion_velocity",
]

PERFORMANCE_CATEGORICAL_FEATURES = [
    "milestone_status",
]

PERFORMANCE_TARGET = "health_score"  # continuous, 0-100 — must not be fabricated

PERFORMANCE_FEATURES = PERFORMANCE_NUMERIC_FEATURES + PERFORMANCE_CATEGORICAL_FEATURES

# =======================================================================
# Convenience registry used by the pipeline orchestrator
# =======================================================================
TASK_SCHEMAS = {
    "delay_prediction": {
        "numeric": DELAY_NUMERIC_FEATURES,
        "categorical": DELAY_CATEGORICAL_FEATURES,
        "features": DELAY_FEATURES,
        "target": DELAY_TARGET,
        "problem_type": "binary_classification",
        "leakage_fields": DELAY_LEAKAGE_FIELDS,
    },
    "risk_analysis": {
        "numeric": RISK_NUMERIC_FEATURES,
        "categorical": RISK_CATEGORICAL_FEATURES,
        "features": RISK_FEATURES,
        "target": RISK_TARGET,
        "problem_type": "multiclass_classification",
        "leakage_fields": [],
    },
    "bottleneck_detection": {
        "numeric": BOTTLENECK_NUMERIC_FEATURES,
        "categorical": BOTTLENECK_CATEGORICAL_FEATURES,
        "features": BOTTLENECK_FEATURES,
        "target": BOTTLENECK_TARGET,          # None -> unsupervised
        "problem_type": "anomaly_detection",
        "leakage_fields": [],
    },
    "performance_analysis": {
        "numeric": PERFORMANCE_NUMERIC_FEATURES,
        "categorical": PERFORMANCE_CATEGORICAL_FEATURES,
        "features": PERFORMANCE_FEATURES,
        "target": PERFORMANCE_TARGET,
        "problem_type": "regression",
        "leakage_fields": [],
    },
}
