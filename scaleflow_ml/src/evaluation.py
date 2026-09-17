"""
ScaleFlow AI/ML Module - Evaluation Utilities
--------------------------------------------------
Evaluation functions matching the metrics defined per model in the
Model Approach document:

    Task Delay Prediction  -> Precision, Recall, F1, ROC-AUC, Accuracy (secondary)
    Risk Analysis          -> Precision, Recall, F1, ROC-AUC, Confusion Matrix
    Bottleneck Detection   -> anomaly score + manual validation
                               (Precision/Recall once labels exist)
    Performance Analysis   -> MAE, RMSE, R²
"""

import os
import json
import numpy as np
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
    confusion_matrix,
    classification_report,
    mean_absolute_error,
    root_mean_squared_error,
    r2_score,
)

from config import REPORTS_DIR


def evaluate_classification(pipeline, X_test, y_test, average: str = "weighted") -> dict:
    """
    Used for Task Delay Prediction and Risk Analysis.
    `average="weighted"` supports both the binary Delay task and the
    multi-class Risk task without code changes. Recall is reported
    explicitly because it is the metric the Model Approach document
    flags as most important for both tasks (missing a genuinely
    delayed/high-risk case defeats the purpose of the prediction).
    """
    y_pred = pipeline.predict(X_test)

    metrics = {
        "accuracy": accuracy_score(y_test, y_pred),          # secondary metric
        "precision": precision_score(y_test, y_pred, average=average, zero_division=0),
        "recall": recall_score(y_test, y_pred, average=average, zero_division=0),
        "f1_score": f1_score(y_test, y_pred, average=average, zero_division=0),
        "confusion_matrix": confusion_matrix(y_test, y_pred).tolist(),
        "classification_report": classification_report(y_test, y_pred, zero_division=0),
    }

    # ROC-AUC only applies cleanly to binary classification with predict_proba.
    if hasattr(pipeline, "predict_proba") and len(set(y_test)) == 2:
        try:
            y_proba = pipeline.predict_proba(X_test)[:, 1]
            metrics["roc_auc"] = roc_auc_score(y_test, y_proba)
        except Exception:
            metrics["roc_auc"] = None

    return metrics


def evaluate_bottleneck_detection(pipeline, X) -> dict:
    """
    Bottleneck Detection has no labeled ground truth yet, so standard
    accuracy/F1 metrics cannot be applied (Model Approach, Section 6).
    Instead this returns the anomaly score and a boolean bottleneck
    flag for each row, ready for manual validation by project managers.
    Once labeled bottleneck outcomes exist, evaluate_classification()
    can be reused with Precision/Recall.
    """
    # decision_function: higher = more normal, lower = more anomalous.
    raw_scores = pipeline.decision_function(X)
    # predict: -1 = anomaly (potential bottleneck), 1 = normal.
    predictions = pipeline.predict(X)

    is_bottleneck = predictions == -1

    metrics = {
        "num_records": int(len(X)),
        "num_flagged_bottlenecks": int(is_bottleneck.sum()),
        "flagged_ratio": float(is_bottleneck.mean()),
        "anomaly_score_mean": float(np.mean(raw_scores)),
        "anomaly_score_min": float(np.min(raw_scores)),
        "anomaly_score_max": float(np.max(raw_scores)),
        "note": (
            "No labeled bottleneck data exists yet. Evaluate by manual "
            "validation of the flagged rows; compute Precision/Recall "
            "once labeled outcomes become available."
        ),
    }
    return metrics, is_bottleneck, raw_scores


def evaluate_regression(pipeline, X_test, y_test) -> dict:
    """Used for the (Phase 2) Project Performance / Health regressor."""
    y_pred = pipeline.predict(X_test)
    metrics = {
        "mae": mean_absolute_error(y_test, y_pred),
        "rmse": root_mean_squared_error(y_test, y_pred),
        "r2": r2_score(y_test, y_pred),
    }
    return metrics


def save_evaluation_report(metrics: dict, task_name: str) -> str:
    """Save an evaluation report (JSON) to artifacts/reports for a task."""
    os.makedirs(REPORTS_DIR, exist_ok=True)
    file_path = os.path.join(REPORTS_DIR, f"{task_name}_evaluation.json")

    # classification_report is plain text; keep it out of the JSON-safe copy
    serializable_metrics = {k: v for k, v in metrics.items() if k != "classification_report"}

    with open(file_path, "w") as f:
        json.dump(serializable_metrics, f, indent=2)

    if "classification_report" in metrics:
        text_report_path = os.path.join(REPORTS_DIR, f"{task_name}_classification_report.txt")
        with open(text_report_path, "w") as f:
            f.write(metrics["classification_report"])

    return file_path


def print_summary(metrics: dict, task_name: str) -> None:
    """Print a short, readable summary of the evaluation metrics."""
    print(f"\n=== Evaluation Summary: {task_name} ===")
    for key, value in metrics.items():
        if key in ("classification_report", "confusion_matrix", "note"):
            continue
        if isinstance(value, float):
            print(f"{key:>10}: {value:.4f}")
        else:
            print(f"{key:>10}: {value}")
