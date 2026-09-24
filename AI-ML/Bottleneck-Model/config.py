"""
config.py
=========
Single source of truth for every path, feature name, and hyperparameter
used across the Bottleneck Detection pipeline (ScaleFlow - ML Problem 3).

Keeping all of this in one place means every other module (data_loader,
preprocessing, model, evaluate, main) imports FROM here instead of
hard-coding strings — so if a column name or a hyperparameter changes,
it only has to change once.
"""

import os

# ---------------------------------------------------------------------------
# PATH CONFIGURATION
# ---------------------------------------------------------------------------
# BASE_DIR = the folder this config.py file lives in, resolved dynamically
# so the pipeline works regardless of where the project folder is placed.
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Location of the raw dataset. Change this if the CSV file is moved.
DATA_PATH = os.path.join(BASE_DIR, "data", "itemlet_dataset.csv")

# Folder where the trained Isolation Forest model (and the fitted
# imputer/scaler that must travel with it) will be persisted.
MODELS_DIR = os.path.join(BASE_DIR, "models")
MODEL_PATH = os.path.join(MODELS_DIR, "bottleneck_isolation_forest.joblib")
PREPROCESSOR_PATH = os.path.join(MODELS_DIR, "bottleneck_preprocessor.joblib")

# Folder where prediction results / reports are written after a run.
OUTPUTS_DIR = os.path.join(BASE_DIR, "outputs")
FLAGGED_ISSUES_PATH = os.path.join(OUTPUTS_DIR, "flagged_bottlenecks.csv")
FULL_RESULTS_PATH = os.path.join(OUTPUTS_DIR, "bottleneck_scores_full.csv")
SUMMARY_REPORT_PATH = os.path.join(OUTPUTS_DIR, "bottleneck_summary_report.txt")

# Make sure the output/model directories exist as soon as config is imported,
# so downstream modules never have to worry about a missing folder.
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(OUTPUTS_DIR, exist_ok=True)


# ---------------------------------------------------------------------------
# IDENTIFIER COLUMNS
# ---------------------------------------------------------------------------
# These are NOT model features. They are kept alongside the predictions
# purely so a human reading the output CSV can tell WHICH issue a given
# anomaly score belongs to.
ID_COLUMNS = [
    "issue_key",
    "issue_summary",
    "project_key",
    "status_name",
    "priority_name",
]


# ---------------------------------------------------------------------------
# BOTTLENECK FEATURE SET
# ---------------------------------------------------------------------------
# Grouped exactly the way the team defined them, for readability and for
# easy inclusion/exclusion of a whole category during experimentation.
#
# NOTE ON NAMING: the raw CSV stores the worklog-total column as the
# lowercase "worklog_total" (not "Worklog Total" as in the original
# brainstorm list). We map to the REAL column name here so the pipeline
# does not crash on a KeyError.

TIME_DURATION_FEATURES = [
    "Cycle Time (hours)",
    "Total Days",
    "issue_age_days",
    "Total Time Logged (hours)",
    "worklog_total",      # <-- mapped from "Worklog Total" to the actual CSV column
    "Worklog Count",
]

PROCESS_FRICTION_FEATURES = [
    "Transition Count",
    "Reassignment Count",
    "Reopen Count",
    "Priority Changes",
    "process_overhead",
    "handoff_complexity",
]

DEPENDENCY_CONNECTIVITY_FEATURES = [
    "Blocking Issues",
    "Blocked By Issues",
    "Number of Inward Links",
    "Number of Outward Links",
    "dependency_complexity",
    "coordination_complexity",
]

COLLABORATION_FEATURES = [
    "work_sessions",
    "comment_count",
    "communication_overhead",
    "collaboration_intensity",
]

REWORK_STATUS_FEATURES = [
    "rework_indicator",
    "has_rework",
    "is_long_running",
    "is_stale",
]

# Final, flattened list of columns that are actually fed into the model.
BOTTLENECK_FEATURES = (
    TIME_DURATION_FEATURES
    + PROCESS_FRICTION_FEATURES
    + DEPENDENCY_CONNECTIVITY_FEATURES
    + COLLABORATION_FEATURES
    + REWORK_STATUS_FEATURES
)

# Boolean-typed columns in the raw CSV that must be cast to 0/1 integers
# before they can be handed to scikit-learn (which expects numeric input).
BOOLEAN_FEATURES = [
    "rework_indicator",
    "has_rework",
    "is_long_running",
]

# ---------------------------------------------------------------------------
# EXCLUDED FEATURES (LEAKAGE RISK) — kept here only for documentation.
# ---------------------------------------------------------------------------
# These are derived / composite risk-scoring columns that could already
# encode "bottleneck-ness" (they are effectively pre-computed answers).
# Isolation Forest must NOT see them, or it would just be re-discovering
# a score someone already calculated instead of learning from raw signals.
# They are listed here (not imported anywhere) purely so the exclusion
# decision is documented in one visible place for the team/exam write-up.
EXCLUDED_LEAKAGE_FEATURES = [
    "effort_risk_score", "effort_risk_z", "effort_risk_raw", "effort_risk_category",
    "complexity_score", "dependency_risk", "effort_predictor_score", "effort_predictor_z",
    "technical_debt_score", "quality_concern",
]


# ---------------------------------------------------------------------------
# PREPROCESSING CONFIGURATION
# ---------------------------------------------------------------------------
# Strategy used to fill missing numeric values before scaling/modeling.
# "median" is robust to the heavy right-skew typical of cycle-time /
# duration data (a few very old or very slow issues would distort a mean).
IMPUTATION_STRATEGY = "median"


# ---------------------------------------------------------------------------
# ISOLATION FOREST HYPERPARAMETERS
# ---------------------------------------------------------------------------
ISOLATION_FOREST_PARAMS = {
    # Number of isolation trees in the ensemble. More trees = more stable
    # anomaly scores, at the cost of training/prediction time.
    "n_estimators": 300,

    # Expected proportion of the dataset that represents true bottlenecks.
    # "auto" lets scikit-learn set the decision threshold itself (based on
    # the original Isolation Forest paper's formula). We instead pin it to
    # an explicit value so the flagged-bottleneck rate is predictable and
    # explainable to stakeholders ("we flag the ~5% most anomalous issues").
    "contamination": 0.05,

    # Number of samples drawn to train each tree. "auto" = min(256, n_samples),
    # which is the setting recommended by the original paper and keeps
    # training fast even on a dataset with hundreds of thousands of rows.
    "max_samples": "auto",

    # Fraction of features considered per tree. 1.0 = use all bottleneck
    # features every time (dataset has already been curated, so no need
    # to sub-sample columns).
    "max_features": 1.0,

    # Fixed seed so every run (and every teammate) gets identical results.
    "random_state": 42,

    # Use every available CPU core to speed up training on a large dataset.
    "n_jobs": -1,
}

# How many of the most-anomalous issues to export as the "flagged" shortlist.
TOP_N_FLAGGED_ISSUES = 50
