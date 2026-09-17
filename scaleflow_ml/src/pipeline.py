"""
ScaleFlow AI/ML Module - Pipeline Orchestrator
----------------------------------------------------
Runs one ML task end-to-end: validate columns -> guard against
leakage -> split features/target -> build model -> train -> evaluate
-> save. Branches by problem_type since Bottleneck Detection is
unsupervised and Performance Analysis is a Phase 2 regression task.
"""

from src.features import TASK_SCHEMAS
from src.preprocessing import (
    basic_data_checks,
    check_no_leakage,
    split_features_target,
    train_test_split_data,
)
from src.models.delay_prediction import build_delay_model
from src.models.risk_analysis import build_risk_model
from src.models.bottleneck_detection import build_bottleneck_model
from src.models.performance_analysis import build_performance_model
from src.training import train_model, cross_validate_model, cross_validate_regressor, save_model
from src.evaluation import (
    evaluate_classification,
    evaluate_bottleneck_detection,
    evaluate_regression,
    save_evaluation_report,
    print_summary,
)

from config import (
    TASK_DELAY_PREDICTION,
    TASK_RISK_ANALYSIS,
    TASK_BOTTLENECK_DETECTION,
    TASK_PERFORMANCE_ANALYSIS,
    MVP_TASKS,
)

MODEL_BUILDERS = {
    TASK_DELAY_PREDICTION: build_delay_model,
    TASK_RISK_ANALYSIS: build_risk_model,
    TASK_BOTTLENECK_DETECTION: build_bottleneck_model,
    TASK_PERFORMANCE_ANALYSIS: build_performance_model,
}


def run_task_pipeline(df, task_name: str, save_artifacts: bool = True) -> dict:
    """
    Run the full pipeline for a single task. Behavior branches by
    problem_type (binary/multiclass classification, anomaly detection,
    or regression) as defined in src/features.py::TASK_SCHEMAS.
    """
    if task_name not in TASK_SCHEMAS:
        raise ValueError(f"Unknown task '{task_name}'. Valid options: {list(TASK_SCHEMAS.keys())}")

    schema = TASK_SCHEMAS[task_name]
    target = schema["target"]
    required_columns = schema["features"] + ([target] if target else [])
    basic_data_checks(df, required_columns)
    check_no_leakage(schema["features"], schema.get("leakage_fields", []))

    X, y = split_features_target(df, schema["features"], target)
    model_builder = MODEL_BUILDERS[task_name]
    pipeline = model_builder()

    # ---- Anomaly detection (Bottleneck Detection): unsupervised ----
    if schema["problem_type"] == "anomaly_detection":
        pipeline = train_model(pipeline, X)  # no y
        metrics, is_bottleneck, scores = evaluate_bottleneck_detection(pipeline, X)
        print_summary(metrics, task_name)
        if save_artifacts:
            model_path = save_model(pipeline, task_name)
            report_path = save_evaluation_report(metrics, task_name)
            print(f"[{task_name}] Model saved to: {model_path}")
            print(f"[{task_name}] Report saved to: {report_path}")
        return {"pipeline": pipeline, "metrics": metrics, "is_bottleneck": is_bottleneck, "scores": scores}

    # ---- Regression (Performance Analysis, Phase 2) ----
    if schema["problem_type"] == "regression":
        X_train, X_test, y_train, y_test = train_test_split_data(X, y, stratify=False)
        cv_scores = cross_validate_regressor(pipeline, X_train, y_train)
        print(f"[{task_name}] Cross-validation neg-MAE: {cv_scores.mean():.4f} +/- {cv_scores.std():.4f}")
        pipeline = train_model(pipeline, X_train, y_train)
        metrics = evaluate_regression(pipeline, X_test, y_test)
        print_summary(metrics, task_name)
        if save_artifacts:
            model_path = save_model(pipeline, task_name)
            report_path = save_evaluation_report(metrics, task_name)
            print(f"[{task_name}] Model saved to: {model_path}")
            print(f"[{task_name}] Report saved to: {report_path}")
        return {"pipeline": pipeline, "metrics": metrics, "cv_scores": cv_scores}

    # ---- Classification (Delay Prediction, Risk Analysis) ----
    X_train, X_test, y_train, y_test = train_test_split_data(X, y, stratify=True)
    cv_scores = cross_validate_model(pipeline, X_train, y_train)
    print(f"[{task_name}] Cross-validation F1 (weighted): {cv_scores.mean():.4f} +/- {cv_scores.std():.4f}")
    pipeline = train_model(pipeline, X_train, y_train)
    metrics = evaluate_classification(pipeline, X_test, y_test)
    print_summary(metrics, task_name)
    if save_artifacts:
        model_path = save_model(pipeline, task_name)
        report_path = save_evaluation_report(metrics, task_name)
        print(f"[{task_name}] Model saved to: {model_path}")
        print(f"[{task_name}] Report saved to: {report_path}")
    return {"pipeline": pipeline, "metrics": metrics, "cv_scores": cv_scores}


def run_mvp_tasks(df) -> dict:
    """
    Run the Phase 1 / MVP tasks only (Model Approach, Section 11):
    Task Delay Prediction, Risk Analysis, Bottleneck Detection.
    Performance Analysis is Phase 2 and is intentionally excluded
    until a reliable numerical health target exists.
    """
    results = {}
    for task_name in MVP_TASKS:
        print(f"\n{'=' * 60}\nRunning pipeline for: {task_name}\n{'=' * 60}")
        results[task_name] = run_task_pipeline(df, task_name)
    return results
