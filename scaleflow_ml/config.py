"""
ScaleFlow AI/ML Module - Global Configuration
------------------------------------------------
Central place for paths, random seed, and shared constants used across
the four ML problems defined in the ScaleFlow AI/ML Model Approach
document:

    1. Task Delay Prediction
    2. Risk Analysis
    3. Bottleneck Detection
    4. Project Performance / Health Analysis (Phase 2)
"""

import os

# ---------------------------------------------------------------------
# Project paths
# ---------------------------------------------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

DATA_DIR = os.path.join(BASE_DIR, "data")
RAW_DATA_DIR = os.path.join(DATA_DIR, "raw")
PROCESSED_DATA_DIR = os.path.join(DATA_DIR, "processed")

ARTIFACTS_DIR = os.path.join(BASE_DIR, "artifacts")
MODELS_DIR = os.path.join(ARTIFACTS_DIR, "models")
REPORTS_DIR = os.path.join(ARTIFACTS_DIR, "reports")

# Expected dataset filename once delivered by the data preparation task.
# Update this once the real file is provided.
RAW_DATASET_FILE = os.path.join(RAW_DATA_DIR, "scaleflow_tasks_dataset.csv")

# ---------------------------------------------------------------------
# Reproducibility
# ---------------------------------------------------------------------
RANDOM_STATE = 42
TEST_SIZE = 0.2

# ---------------------------------------------------------------------
# Cross-validation
# ---------------------------------------------------------------------
CV_FOLDS = 5

# ---------------------------------------------------------------------
# Task identifiers (used for saving/loading models and reports)
# ---------------------------------------------------------------------
TASK_DELAY_PREDICTION = "delay_prediction"
TASK_RISK_ANALYSIS = "risk_analysis"
TASK_BOTTLENECK_DETECTION = "bottleneck_detection"
TASK_PERFORMANCE_ANALYSIS = "performance_analysis"  # Phase 2 (deferred)

# Phase 1 = MVP models that can be built now.
# Phase 2 = deferred until a reliable numerical health target exists.
MVP_TASKS = [TASK_DELAY_PREDICTION, TASK_RISK_ANALYSIS, TASK_BOTTLENECK_DETECTION]
ALL_TASKS = MVP_TASKS + [TASK_PERFORMANCE_ANALYSIS]

# ---------------------------------------------------------------------
# Bottleneck Detection (unsupervised) — expected proportion of tasks
# flagged as bottleneck/anomalous. Adjustable once real data is seen.
# ---------------------------------------------------------------------
BOTTLENECK_CONTAMINATION = 0.1
