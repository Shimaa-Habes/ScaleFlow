from pathlib import Path
import gc
import json
import warnings

import joblib
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from sklearn.ensemble import (
    IsolationForest,
    RandomForestClassifier,
    RandomForestRegressor,
)
from sklearn.metrics import (
    ConfusionMatrixDisplay,
    RocCurveDisplay,
    accuracy_score,
    f1_score,
    mean_absolute_error,
    mean_squared_error,
    precision_score,
    r2_score,
    recall_score,
    roc_auc_score,
)

# ------------------------------------------------------------
# 1. Basic settings
# ------------------------------------------------------------

warnings.filterwarnings("ignore", category=UserWarning)

pd.set_option("display.max_columns", 100)
pd.set_option("display.width", 160)
pd.set_option("display.float_format", lambda x: f"{x:,.4f}")

RANDOM_STATE = 42

# Keep None to use the full Training dataset.
# For a quick test on a small laptop, use a smaller number such as 200_000.
MAX_TRAIN_ROWS = None


# ------------------------------------------------------------
# 2. Find the ScaleFlow AI_ML folder
# ------------------------------------------------------------

def find_ai_ml_dir():
    """Find the AI_ML folder from common project locations."""

    candidates = []

    # First try the location of this Python file.
    try:
        script_dir = Path(__file__).resolve().parent
        candidates.extend([
            script_dir,
            script_dir.parent,
            *script_dir.parents,
        ])
    except NameError:
        pass

    # Also try the current terminal location.
    current_dir = Path.cwd().resolve()
    candidates.extend([
        current_dir,
        *current_dir.parents,
    ])

    checked = set()

    for candidate in candidates:
        if candidate in checked:
            continue
        checked.add(candidate)

        # We are already inside AI_ML.
        if candidate.name == "AI_ML" and (candidate / "Data" / "processed").exists():
            return candidate

        # Repository contains ScaleFlow/AI_ML.
        nested = candidate / "ScaleFlow" / "AI_ML"
        if (nested / "Data" / "processed").exists():
            return nested

        # Repository contains AI_ML directly.
        direct = candidate / "AI_ML"
        if (direct / "Data" / "processed").exists():
            return direct

    raise FileNotFoundError(
        "AI_ML/Data/processed was not found. "
        "Put this file inside AI_ML/Python_Files or run it from the ScaleFlow project."
    )


AI_ML_DIR = find_ai_ml_dir()

PROCESSED_DIR = AI_ML_DIR / "Data" / "processed"
MODELS_DIR = AI_ML_DIR / "Models"
RESULTS_DIR = AI_ML_DIR / "Results"

MODELS_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

print("=" * 70)
print("ScaleFlow - Train & Evaluate ML Baseline Models")
print("=" * 70)
print("AI_ML folder:", AI_ML_DIR)
print("Processed data:", PROCESSED_DIR)
print("Models output:", MODELS_DIR)
print("Results output:", RESULTS_DIR)


# ------------------------------------------------------------
# 3. Define input files
# ------------------------------------------------------------

TRAIN_CSV_PATH = PROCESSED_DIR / "train.csv"
TRAIN_ZIP_PATH = PROCESSED_DIR / "train.zip"
VALIDATION_PATH = PROCESSED_DIR / "validation.csv"
TEST_PATH = PROCESSED_DIR / "test.csv"
BOTTLENECK_PATH = PROCESSED_DIR / "bottleneck_dataset.csv"
METADATA_PATH = PROCESSED_DIR / "preprocessing_metadata.json"

# Use train.csv when it exists.
# train.zip is only a fallback.
if TRAIN_CSV_PATH.exists():
    TRAIN_PATH = TRAIN_CSV_PATH
elif TRAIN_ZIP_PATH.exists():
    TRAIN_PATH = TRAIN_ZIP_PATH
else:
    raise FileNotFoundError(
        "Neither train.csv nor train.zip was found in Data/processed."
    )

required_files = [
    VALIDATION_PATH,
    TEST_PATH,
    BOTTLENECK_PATH,
    METADATA_PATH,
]

missing_files = [path.name for path in required_files if not path.exists()]

if missing_files:
    raise FileNotFoundError(
        "Missing required files: " + ", ".join(missing_files)
    )

print("\nInput files are ready.")
print("Training file:", TRAIN_PATH.name)


# ------------------------------------------------------------
# 4. Load preprocessing metadata
# ------------------------------------------------------------

with open(METADATA_PATH, "r", encoding="utf-8") as file:
    metadata = json.load(file)

# Model 1: Regression
REGRESSION_TARGET = metadata["models"]["regression"]["target"]
REGRESSION_FEATURES = metadata["models"]["regression"]["features"]

# Model 2: Classification
CLASSIFICATION_TARGET = metadata["models"]["classification"]["target"]
CLASSIFICATION_FEATURES = metadata["models"]["classification"]["features"]

# Model 3: Isolation Forest
BOTTLENECK_TARGET = metadata["models"]["bottleneck_isolation_forest"]["target"]
BOTTLENECK_FEATURES = metadata["models"]["bottleneck_isolation_forest"]["features"]

print("\nModel setup:")
print("1. Regression target:", REGRESSION_TARGET)
print("2. Classification target:", CLASSIFICATION_TARGET)
print("3. Isolation Forest target:", BOTTLENECK_TARGET)

# Both supervised models should use the same prepared feature matrix.
assert REGRESSION_FEATURES == CLASSIFICATION_FEATURES, (
    "Regression and Classification feature lists are different."
)

SUPERVISED_FEATURES = REGRESSION_FEATURES

print("Supervised feature count:", len(SUPERVISED_FEATURES))
print("Bottleneck feature count:", len(BOTTLENECK_FEATURES))


# ------------------------------------------------------------
# 5. Load Train / Validation / Test data
# ------------------------------------------------------------

# Use smaller data types to reduce memory usage.
dtype_map = {}

for column in SUPERVISED_FEATURES:
    if (
        column.startswith("project_key_")
        or column.startswith("priority_")
        or column.startswith("issue_type_")
        or column in ["is_subtask", "created_month", "created_dayofweek"]
    ):
        dtype_map[column] = "int8"
    elif column == "created_year":
        dtype_map[column] = "int16"
    else:
        dtype_map[column] = "float32"

dtype_map[REGRESSION_TARGET] = "float32"
dtype_map[CLASSIFICATION_TARGET] = "int8"

supervised_columns = [
    "task_key",
    *SUPERVISED_FEATURES,
    REGRESSION_TARGET,
    CLASSIFICATION_TARGET,
]


def read_supervised_split(path):
    """Load one prepared supervised split."""

    compression = "zip" if path.suffix.lower() == ".zip" else None

    return pd.read_csv(
        path,
        usecols=supervised_columns,
        dtype=dtype_map,
        compression=compression,
        low_memory=False,
    )


print("\nLoading Train data...")
train_df = read_supervised_split(TRAIN_PATH)

print("Loading Validation data...")
validation_df = read_supervised_split(VALIDATION_PATH)

print("Loading Test data...")
test_df = read_supervised_split(TEST_PATH)

print("Train shape:", train_df.shape)
print("Validation shape:", validation_df.shape)
print("Test shape:", test_df.shape)


# ------------------------------------------------------------
# 6. Separate features, targets, and task IDs
# ------------------------------------------------------------

train_ids = train_df.pop("task_key")
validation_ids = validation_df.pop("task_key")
test_ids = test_df.pop("task_key")

# Regression target
y_train_reg = train_df.pop(REGRESSION_TARGET)
y_validation_reg = validation_df.pop(REGRESSION_TARGET)
y_test_reg = test_df.pop(REGRESSION_TARGET)

# Classification target
y_train_cls = train_df.pop(CLASSIFICATION_TARGET)
y_validation_cls = validation_df.pop(CLASSIFICATION_TARGET)
y_test_cls = test_df.pop(CLASSIFICATION_TARGET)

# The remaining columns are model input features.
X_train = train_df
X_validation = validation_df
X_test = test_df

# Optional quick test on fewer Training rows.
if MAX_TRAIN_ROWS is not None and len(X_train) > MAX_TRAIN_ROWS:
    sample_index = X_train.sample(
        n=MAX_TRAIN_ROWS,
        random_state=RANDOM_STATE,
    ).index

    X_train = X_train.loc[sample_index].copy()
    y_train_reg = y_train_reg.loc[sample_index].copy()
    y_train_cls = y_train_cls.loc[sample_index].copy()
    train_ids = train_ids.loc[sample_index].copy()

print("\nTraining rows used:", f"{len(X_train):,}")
print("Feature count:", X_train.shape[1])


# ------------------------------------------------------------
# 7. Validate the supervised datasets
# ------------------------------------------------------------

# All splits must use exactly the same features.
assert list(X_train.columns) == SUPERVISED_FEATURES
assert list(X_validation.columns) == SUPERVISED_FEATURES
assert list(X_test.columns) == SUPERVISED_FEATURES

# Targets must not contain missing values.
assert y_train_reg.notna().all()
assert y_validation_reg.notna().all()
assert y_test_reg.notna().all()

assert y_train_cls.notna().all()
assert y_validation_cls.notna().all()
assert y_test_cls.notna().all()

# Model features must not contain missing values.
assert X_train.isna().sum().sum() == 0
assert X_validation.isna().sum().sum() == 0
assert X_test.isna().sum().sum() == 0

print("Supervised data checks passed.")


# ------------------------------------------------------------
# 8. Helper functions for evaluation
# ------------------------------------------------------------

def get_regression_metrics(y_true, y_pred):
    """Return the main Regression metrics."""

    return {
        "MAE": mean_absolute_error(y_true, y_pred),
        "RMSE": np.sqrt(mean_squared_error(y_true, y_pred)),
        "R2": r2_score(y_true, y_pred),
    }


def get_classification_metrics(y_true, y_pred, y_probability):
    """Return the main Classification metrics."""

    return {
        "Accuracy": accuracy_score(y_true, y_pred),
        "Precision": precision_score(
            y_true,
            y_pred,
            zero_division=0,
        ),
        "Recall": recall_score(
            y_true,
            y_pred,
            zero_division=0,
        ),
        "F1": f1_score(
            y_true,
            y_pred,
            zero_division=0,
        ),
        "ROC_AUC": roc_auc_score(
            y_true,
            y_probability,
        ),
    }


# ------------------------------------------------------------
# 9. MODEL 1 - Random Forest Regression
# Target: resolution_time_days
# ------------------------------------------------------------

print("\n" + "=" * 70)
print("MODEL 1 - REGRESSION")
print("Target:", REGRESSION_TARGET)
print("=" * 70)

# Create the baseline Regression model.
regression_model = RandomForestRegressor(
    n_estimators=100,
    max_depth=20,
    min_samples_leaf=4,
    max_features="sqrt",
    random_state=RANDOM_STATE,
    n_jobs=-1,
)

print("Training Random Forest Regressor...")
regression_model.fit(X_train, y_train_reg)
print("Regression training complete.")

# Create predictions.
validation_reg_pred = regression_model.predict(X_validation)
test_reg_pred = regression_model.predict(X_test)

# Calculate evaluation metrics.
regression_validation_metrics = get_regression_metrics(
    y_validation_reg,
    validation_reg_pred,
)

regression_test_metrics = get_regression_metrics(
    y_test_reg,
    test_reg_pred,
)

print("\nRegression Validation metrics:")
for name, value in regression_validation_metrics.items():
    print(f"- {name}: {value:.4f}")

print("\nRegression Test metrics:")
for name, value in regression_test_metrics.items():
    print(f"- {name}: {value:.4f}")

# Save Test predictions.
REGRESSION_PREDICTIONS_PATH = (
    RESULTS_DIR / "regression_test_predictions.csv"
)

regression_test_results = pd.DataFrame({
    "task_key": test_ids.values,
    "actual_resolution_time_days": y_test_reg.values,
    "predicted_resolution_time_days": test_reg_pred,
})

regression_test_results.to_csv(
    REGRESSION_PREDICTIONS_PATH,
    index=False,
)

# Save feature importance.
REGRESSION_IMPORTANCE_PATH = (
    RESULTS_DIR / "regression_feature_importance.csv"
)

regression_importance = pd.DataFrame({
    "feature": SUPERVISED_FEATURES,
    "importance": regression_model.feature_importances_,
}).sort_values(
    "importance",
    ascending=False,
)

regression_importance.to_csv(
    REGRESSION_IMPORTANCE_PATH,
    index=False,
)

# Save Actual vs Predicted plot.
REGRESSION_PLOT_PATH = (
    RESULTS_DIR / "regression_actual_vs_predicted.png"
)

plot_size = min(5_000, len(y_test_reg))
rng = np.random.default_rng(RANDOM_STATE)
plot_index = rng.choice(
    len(y_test_reg),
    size=plot_size,
    replace=False,
)

plt.figure(figsize=(8, 6))
plt.scatter(
    y_test_reg.iloc[plot_index],
    test_reg_pred[plot_index],
    alpha=0.25,
)
plt.xlabel("Actual resolution time (days)")
plt.ylabel("Predicted resolution time (days)")
plt.title("Regression: Actual vs Predicted Resolution Time")
plt.tight_layout()
plt.savefig(REGRESSION_PLOT_PATH, dpi=150)
plt.close()

# Save feature importance plot.
REGRESSION_IMPORTANCE_PLOT_PATH = (
    RESULTS_DIR / "regression_feature_importance.png"
)

top_regression_features = (
    regression_importance
    .head(15)
    .sort_values("importance")
)

plt.figure(figsize=(9, 6))
plt.barh(
    top_regression_features["feature"],
    top_regression_features["importance"],
)
plt.xlabel("Feature importance")
plt.title("Regression: Top 15 Feature Importances")
plt.tight_layout()
plt.savefig(
    REGRESSION_IMPORTANCE_PLOT_PATH,
    dpi=150,
)
plt.close()

# Save the Regression model.
REGRESSION_MODEL_PATH = (
    MODELS_DIR / "random_forest_regression.joblib"
)

joblib.dump(
    regression_model,
    REGRESSION_MODEL_PATH,
)

print("Saved model:", REGRESSION_MODEL_PATH)
print("Saved predictions:", REGRESSION_PREDICTIONS_PATH)

# Free memory before the next model.
del regression_model
gc.collect()


# ------------------------------------------------------------
# 10. MODEL 2 - Random Forest Classification
# Target: long_resolution_risk
# ------------------------------------------------------------

print("\n" + "=" * 70)
print("MODEL 2 - CLASSIFICATION")
print("Target:", CLASSIFICATION_TARGET)
print("=" * 70)

# class_weight='balanced' helps with class imbalance.
classification_model = RandomForestClassifier(
    n_estimators=100,
    max_depth=20,
    min_samples_leaf=2,
    max_features="sqrt",
    class_weight="balanced",
    random_state=RANDOM_STATE,
    n_jobs=-1,
)

print("Training Random Forest Classifier...")
classification_model.fit(
    X_train,
    y_train_cls,
)
print("Classification training complete.")

# Validation predictions and probabilities.
validation_cls_pred = classification_model.predict(
    X_validation
)

validation_cls_probability = (
    classification_model
    .predict_proba(X_validation)[:, 1]
)

# Test predictions and probabilities.
test_cls_pred = classification_model.predict(
    X_test
)

test_cls_probability = (
    classification_model
    .predict_proba(X_test)[:, 1]
)

# Calculate evaluation metrics.
classification_validation_metrics = (
    get_classification_metrics(
        y_validation_cls,
        validation_cls_pred,
        validation_cls_probability,
    )
)

classification_test_metrics = (
    get_classification_metrics(
        y_test_cls,
        test_cls_pred,
        test_cls_probability,
    )
)

print("\nClassification Validation metrics:")
for name, value in classification_validation_metrics.items():
    print(f"- {name}: {value:.4f}")

print("\nClassification Test metrics:")
for name, value in classification_test_metrics.items():
    print(f"- {name}: {value:.4f}")

# Save Test predictions and probabilities.
CLASSIFICATION_PREDICTIONS_PATH = (
    RESULTS_DIR / "classification_test_predictions.csv"
)

classification_test_results = pd.DataFrame({
    "task_key": test_ids.values,
    "actual_long_resolution_risk": y_test_cls.values,
    "predicted_long_resolution_risk": test_cls_pred,
    "risk_probability": test_cls_probability,
})

classification_test_results.to_csv(
    CLASSIFICATION_PREDICTIONS_PATH,
    index=False,
)

# Save feature importance.
CLASSIFICATION_IMPORTANCE_PATH = (
    RESULTS_DIR / "classification_feature_importance.csv"
)

classification_importance = pd.DataFrame({
    "feature": SUPERVISED_FEATURES,
    "importance": classification_model.feature_importances_,
}).sort_values(
    "importance",
    ascending=False,
)

classification_importance.to_csv(
    CLASSIFICATION_IMPORTANCE_PATH,
    index=False,
)

# Save Confusion Matrix plot.
CONFUSION_MATRIX_PATH = (
    RESULTS_DIR / "classification_confusion_matrix.png"
)

ConfusionMatrixDisplay.from_predictions(
    y_test_cls,
    test_cls_pred,
    display_labels=[
        "Lower Risk",
        "Long Resolution Risk",
    ],
    values_format=",",
)

plt.title("Classification: Test Confusion Matrix")
plt.tight_layout()
plt.savefig(
    CONFUSION_MATRIX_PATH,
    dpi=150,
)
plt.close()

# Save ROC Curve plot.
ROC_CURVE_PATH = (
    RESULTS_DIR / "classification_roc_curve.png"
)

RocCurveDisplay.from_predictions(
    y_test_cls,
    test_cls_probability,
)

plt.title("Classification: Test ROC Curve")
plt.tight_layout()
plt.savefig(
    ROC_CURVE_PATH,
    dpi=150,
)
plt.close()

# Save feature importance plot.
CLASSIFICATION_IMPORTANCE_PLOT_PATH = (
    RESULTS_DIR / "classification_feature_importance.png"
)

top_classification_features = (
    classification_importance
    .head(15)
    .sort_values("importance")
)

plt.figure(figsize=(9, 6))
plt.barh(
    top_classification_features["feature"],
    top_classification_features["importance"],
)
plt.xlabel("Feature importance")
plt.title("Classification: Top 15 Feature Importances")
plt.tight_layout()
plt.savefig(
    CLASSIFICATION_IMPORTANCE_PLOT_PATH,
    dpi=150,
)
plt.close()

# Save the Classification model.
CLASSIFICATION_MODEL_PATH = (
    MODELS_DIR / "random_forest_classification.joblib"
)

joblib.dump(
    classification_model,
    CLASSIFICATION_MODEL_PATH,
)

print("Saved model:", CLASSIFICATION_MODEL_PATH)
print("Saved predictions:", CLASSIFICATION_PREDICTIONS_PATH)

# Free memory before Isolation Forest.
del classification_model
gc.collect()


# ------------------------------------------------------------
# 11. MODEL 3 - Isolation Forest
# Target: None
# Outputs: anomaly_score + potential_bottleneck
# ------------------------------------------------------------

print("\n" + "=" * 70)
print("MODEL 3 - ISOLATION FOREST")
print("Target: None")
print("=" * 70)

# Load only the columns needed for Bottleneck Detection.
bottleneck_columns = [
    "task_key",
    "project_key",
    "created_date",
    *BOTTLENECK_FEATURES,
]

bottleneck_df = pd.read_csv(
    BOTTLENECK_PATH,
    usecols=bottleneck_columns,
    low_memory=False,
)

print("Bottleneck dataset shape:", bottleneck_df.shape)

# Keep task information for the final output.
bottleneck_info = bottleneck_df[[
    "task_key",
    "project_key",
    "created_date",
]].copy()

# Isolation Forest uses only numerical bottleneck features.
X_bottleneck = (
    bottleneck_df[BOTTLENECK_FEATURES]
    .astype("float32")
)

# Bottleneck model inputs must be complete.
assert X_bottleneck.isna().sum().sum() == 0

print(
    "Isolation Forest input shape:",
    X_bottleneck.shape,
)

# Create the unsupervised model.
# contamination='auto' avoids inventing a fixed bottleneck percentage.
isolation_forest_model = IsolationForest(
    n_estimators=200,
    max_samples="auto",
    contamination="auto",
    random_state=RANDOM_STATE,
    n_jobs=-1,
)

print("Training Isolation Forest...")
isolation_forest_model.fit(X_bottleneck)
print("Isolation Forest training complete.")

# score_samples gives smaller values for unusual rows.
# Reverse the sign so a larger score means a more unusual task.
raw_anomaly_score = (
    -isolation_forest_model
    .score_samples(X_bottleneck)
)

# Normalize anomaly score to a simple 0-1 range.
score_min = raw_anomaly_score.min()
score_max = raw_anomaly_score.max()

if score_max > score_min:
    anomaly_score = (
        (raw_anomaly_score - score_min)
        / (score_max - score_min)
    )
else:
    anomaly_score = np.zeros_like(
        raw_anomaly_score
    )

# Isolation Forest returns:
# -1 = anomaly
#  1 = normal
isolation_prediction = (
    isolation_forest_model
    .predict(X_bottleneck)
)

potential_bottleneck = (
    isolation_prediction == -1
).astype("int8")

# Build the final Bottleneck output.
bottleneck_results = bottleneck_info.copy()

bottleneck_results["anomaly_score"] = (
    anomaly_score
)

bottleneck_results["potential_bottleneck"] = (
    potential_bottleneck
)

potential_bottleneck_count = int(
    potential_bottleneck.sum()
)

potential_bottleneck_rate = float(
    potential_bottleneck.mean()
)

print(
    "Potential bottlenecks:",
    f"{potential_bottleneck_count:,}",
)

print(
    "Potential bottleneck rate:",
    f"{potential_bottleneck_rate * 100:.2f}%",
)

# Save all Bottleneck predictions.
BOTTLENECK_RESULTS_PATH = (
    RESULTS_DIR / "bottleneck_predictions.csv"
)

bottleneck_results.to_csv(
    BOTTLENECK_RESULTS_PATH,
    index=False,
)

# Save the tasks with the highest anomaly scores.
TOP_BOTTLENECKS_PATH = (
    RESULTS_DIR / "top_potential_bottlenecks.csv"
)

top_potential_bottlenecks = (
    bottleneck_results
    .sort_values(
        "anomaly_score",
        ascending=False,
    )
    .head(30)
)

top_potential_bottlenecks.to_csv(
    TOP_BOTTLENECKS_PATH,
    index=False,
)

# Save anomaly-score distribution plot.
BOTTLENECK_PLOT_PATH = (
    RESULTS_DIR / "bottleneck_anomaly_score_distribution.png"
)

plt.figure(figsize=(8, 5))
plt.hist(
    bottleneck_results["anomaly_score"],
    bins=50,
)
plt.xlabel("Normalized anomaly score")
plt.ylabel("Number of tasks")
plt.title("Isolation Forest: Anomaly Score Distribution")
plt.tight_layout()
plt.savefig(
    BOTTLENECK_PLOT_PATH,
    dpi=150,
)
plt.close()

# Save the Isolation Forest model.
ISOLATION_MODEL_PATH = (
    MODELS_DIR / "isolation_forest_bottleneck.joblib"
)

joblib.dump(
    isolation_forest_model,
    ISOLATION_MODEL_PATH,
)

print("Saved model:", ISOLATION_MODEL_PATH)
print("Saved predictions:", BOTTLENECK_RESULTS_PATH)


# ------------------------------------------------------------
# 12. Save metrics for all three models
# ------------------------------------------------------------

metrics_output = {
    "regression": {
        "target": REGRESSION_TARGET,
        "validation": {
            key: float(value)
            for key, value
            in regression_validation_metrics.items()
        },
        "test": {
            key: float(value)
            for key, value
            in regression_test_metrics.items()
        },
    },

    "classification": {
        "target": CLASSIFICATION_TARGET,
        "validation": {
            key: float(value)
            for key, value
            in classification_validation_metrics.items()
        },
        "test": {
            key: float(value)
            for key, value
            in classification_test_metrics.items()
        },
    },

    "bottleneck_isolation_forest": {
        "target": None,
        "rows_scored": int(
            len(bottleneck_results)
        ),
        "potential_bottlenecks": (
            potential_bottleneck_count
        ),
        "potential_bottleneck_rate": (
            potential_bottleneck_rate
        ),
        "output_columns": [
            "anomaly_score",
            "potential_bottleneck",
        ],
    },
}

METRICS_PATH = (
    RESULTS_DIR / "baseline_model_metrics.json"
)

with open(
    METRICS_PATH,
    "w",
    encoding="utf-8",
) as file:
    json.dump(
        metrics_output,
        file,
        indent=2,
    )

print("\nSaved metrics:", METRICS_PATH)


# ------------------------------------------------------------
# 13. Save model handoff information
# ------------------------------------------------------------

# This file helps the next developer understand each saved model.
handoff = {
    "supervised_feature_count": len(
        SUPERVISED_FEATURES
    ),

    "supervised_features": (
        SUPERVISED_FEATURES
    ),

    "regression": {
        "model_file": (
            REGRESSION_MODEL_PATH.name
        ),
        "target": REGRESSION_TARGET,
        "prediction_meaning": (
            "Predicted resolution time in days"
        ),
    },

    "classification": {
        "model_file": (
            CLASSIFICATION_MODEL_PATH.name
        ),
        "target": CLASSIFICATION_TARGET,
        "prediction_meaning": (
            "Long resolution risk proxy "
            "(0 or 1) and probability"
        ),
        "risk_threshold_days": metadata.get(
            "risk_threshold_days"
        ),
    },

    "bottleneck_isolation_forest": {
        "model_file": (
            ISOLATION_MODEL_PATH.name
        ),
        "target": None,
        "features": BOTTLENECK_FEATURES,
        "prediction_outputs": [
            "anomaly_score",
            "potential_bottleneck",
        ],
        "note": (
            "potential_bottleneck is a model output, "
            "not a ground-truth target"
        ),
    },
}

HANDOFF_PATH = (
    RESULTS_DIR / "model_handoff.json"
)

with open(
    HANDOFF_PATH,
    "w",
    encoding="utf-8",
) as file:
    json.dump(
        handoff,
        file,
        indent=2,
    )

print("Saved handoff file:", HANDOFF_PATH)


# ------------------------------------------------------------
# 14. Final summary
# ------------------------------------------------------------

print("\n" + "=" * 70)
print("FINAL MODEL SUMMARY")
print("=" * 70)

print("\n1. Regression")
print("Target:", REGRESSION_TARGET)
print(
    "Test MAE:",
    f"{regression_test_metrics['MAE']:.4f}",
)
print(
    "Test RMSE:",
    f"{regression_test_metrics['RMSE']:.4f}",
)
print(
    "Test R2:",
    f"{regression_test_metrics['R2']:.4f}",
)

print("\n2. Classification")
print("Target:", CLASSIFICATION_TARGET)
print(
    "Test Accuracy:",
    f"{classification_test_metrics['Accuracy']:.4f}",
)
print(
    "Test Precision:",
    f"{classification_test_metrics['Precision']:.4f}",
)
print(
    "Test Recall:",
    f"{classification_test_metrics['Recall']:.4f}",
)
print(
    "Test F1:",
    f"{classification_test_metrics['F1']:.4f}",
)
print(
    "Test ROC-AUC:",
    f"{classification_test_metrics['ROC_AUC']:.4f}",
)

print("\n3. Isolation Forest")
print("Target: None")
print(
    "Potential bottlenecks:",
    f"{potential_bottleneck_count:,}",
)
print(
    "Potential bottleneck rate:",
    f"{potential_bottleneck_rate * 100:.2f}%",
)
print(
    "Outputs: anomaly_score + potential_bottleneck"
)

print("\nModels saved in:")
print(MODELS_DIR)

print("\nResults saved in:")
print(RESULTS_DIR)

print("\nTrain & Evaluate task completed.")
