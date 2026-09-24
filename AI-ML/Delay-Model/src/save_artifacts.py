"""
save_artifacts.py
------------------
Step 13: persist everything the project produced:
 - the trained model itself (.joblib, so it can be loaded later without retraining)
 - metadata describing the model's inputs (class mapping, feature schema)
 - the test-set predictions
 - one combined JSON report with every metric computed earlier
"""

import json

import joblib
import pandas as pd

from .config import CLASS_NAMES, MODEL_DIR, OUTPUT_DIR, REPORT_DIR, SEARCH_SCORING
from .features import FEATURE_COLUMNS


def save_model_and_metadata(best_model):
    """Save the fitted model plus two small JSON files describing how to use it."""
    joblib.dump(best_model, MODEL_DIR / "jira_resolution_class_model.joblib")

    (MODEL_DIR / "class_mapping.json").write_text(json.dumps(dict(enumerate(CLASS_NAMES)), indent=2))

    (MODEL_DIR / "feature_schema.json").write_text(
        json.dumps(
            {
                "raw_input_columns": ["Summary", "Description", "Labels", "Priority", "Created"],
                "model_input_columns": FEATURE_COLUMNS,
                "note": "Call build_features() on the raw columns first; the saved pipeline expects its output.",
            },
            indent=2,
        )
    )


def save_predictions_and_report(
    clean_df,
    idx_test,
    y_test,
    y_pred,
    y_proba,
    best_model,
    importance_df,
    report_df,
    raw_df,
    X_train,
    X_test,
    ablation,
    comparison,
    tuning_table,
    final_comparison,
    best_name,
    test_metrics,
):
    """Save the per-ticket test predictions (with class probabilities) and one
    combined JSON report summarizing every stage of the project."""
    predictions = pd.DataFrame(
        {
            "Summary": clean_df.loc[idx_test, "Summary"].to_numpy(),
            "actual": [CLASS_NAMES[c] for c in y_test],
            "predicted": [CLASS_NAMES[c] for c in y_pred],
            "correct": (y_test.to_numpy() == y_pred),
        }
    )
    for position, class_code in enumerate(best_model.classes_):
        predictions[f"prob_{CLASS_NAMES[int(class_code)]}"] = y_proba[:, position].round(4)
    predictions.to_csv(REPORT_DIR / "test_predictions.csv", index=False, encoding="utf-8-sig")

    importance_df.to_csv(REPORT_DIR / "permutation_importance.csv", index=False)
    report_df.to_csv(REPORT_DIR / "classification_report.csv")

    full_report = {
        "dataset": {"rows_raw": len(raw_df), "rows_clean": len(clean_df), "train": len(X_train), "test": len(X_test)},
        "classes": CLASS_NAMES,
        "duration_cuts_days": [30, 365],
        "ablation_cv": ablation.round(4).to_dict(orient="index"),
        "model_comparison_cv": comparison.round(4).to_dict(orient="index"),
        "tuned_models": {
            k: {
                "params": {p: (v if isinstance(v, (int, float, str, type(None))) else str(v)) for p, v in row["best_params"].items()},
                "cv": row[f"best_cv_{SEARCH_SCORING}"],
            }
            for k, row in tuning_table.iterrows()
        },
        "final_comparison_cv": final_comparison.round(4).to_dict(orient="index"),
        "selected_model": best_name,
        "test_metrics_random_split": test_metrics,
    }
    (REPORT_DIR / "model_report.json").write_text(json.dumps(full_report, indent=2, default=str))

    print("Saved:")
    for path in sorted(OUTPUT_DIR.rglob("*")):
        if path.is_file() and ".cache" not in path.parts:
            print(" ", path)
