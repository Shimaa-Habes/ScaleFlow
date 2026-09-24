import pandas as pd

from sklearn.model_selection import train_test_split
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler


# Features that directly reveal the final project outcome.
LEAKAGE_FEATURES = [
    "elapsed_hours",
    "duration_variance_hours",
    "duration_ratio",
    "task_elapsed_hours",
    "task_duration_variance_hours",
    "task_duration_ratio",
]


# Features that are not useful for model training.
NON_MODEL_FEATURES = [
    "project_id",
    "created_at",
]


def prepare_dataset(project_features: pd.DataFrame):
    """
    Prepare project features and create the binary health target.

    Target:
        0 = Project stayed within planned budget
        1 = Project exceeded planned budget
    """

    print("\n=== PREPARING HEALTH DATASET ===")

    df = project_features.copy()

    # Create the target from the final budget outcome.
    df["failed_budget"] = (
        (df["planned_hours"] > 0)
        & (df["elapsed_hours"] > df["planned_hours"])
    ).astype(int)

    # Keep only projects with a valid planned budget.
    df = df[df["planned_hours"] > 0].copy()

    print(f"Projects with valid target: {len(df):,}")

    # Remove columns that would directly expose the target.
    columns_to_drop = (
        LEAKAGE_FEATURES
        + NON_MODEL_FEATURES
    )

    X = df.drop(
        columns=columns_to_drop + ["failed_budget"],
        errors="ignore",
    )

    y = df["failed_budget"]

    print(f"Training features: {X.shape[1]}")
    print(f"Successful projects: {(y == 0).sum():,}")
    print(f"Failed projects: {(y == 1).sum():,}")

    # Split the data while preserving the class distribution.
    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.20,
        random_state=42,
        stratify=y,
    )

    # Convert all remaining values to numeric values.
    X_train = X_train.apply(
        pd.to_numeric,
        errors="coerce",
    )

    X_test = X_test.apply(
        pd.to_numeric,
        errors="coerce",
    )

    # Replace missing values with the median from the training data.
    imputer = SimpleImputer(strategy="median")

    X_train_imputed = imputer.fit_transform(X_train)
    X_test_imputed = imputer.transform(X_test)

    # Standardize numeric features for the ML model.
    scaler = StandardScaler()

    X_train_scaled = scaler.fit_transform(
        X_train_imputed
    )

    X_test_scaled = scaler.transform(
        X_test_imputed
    )

    print(f"Training samples: {len(X_train):,}")
    print(f"Testing samples: {len(X_test):,}")

    return (
        X_train_scaled,
        X_test_scaled,
        y_train,
        y_test,
        imputer,
        scaler,
        X.columns.tolist(),
    )