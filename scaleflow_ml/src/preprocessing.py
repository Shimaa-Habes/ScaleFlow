"""
ScaleFlow AI/ML Module - Preprocessing
-----------------------------------------
Reusable functions to load the prepared dataset, validate it, guard
against data leakage, and build a scikit-learn preprocessing pipeline
(imputation + encoding + scaling) for any of the four modeling tasks.
"""

import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.model_selection import train_test_split

from config import RANDOM_STATE, TEST_SIZE


def load_dataset(file_path: str) -> pd.DataFrame:
    """
    Load the prepared dataset produced by the data preparation task.

    Expects a single tabular file (CSV) containing the columns needed
    by every task's feature schema, plus the applicable target columns.
    """
    df = pd.read_csv(file_path)
    df = df.drop_duplicates()
    return df


def basic_data_checks(df: pd.DataFrame, required_columns: list) -> None:
    """
    Validate that the dataset contains the columns a given task needs.
    Raises a clear error early instead of failing deep inside training.
    """
    missing = [col for col in required_columns if col not in df.columns]
    if missing:
        raise ValueError(
            f"Dataset is missing required columns: {missing}. "
            "Confirm the data preparation task has produced these fields."
        )


def check_no_leakage(feature_list: list, leakage_fields: list) -> None:
    """
    Guard against data leakage (Model Approach, Section 10). Task Delay
    Prediction must never use fields that are only available after a
    task is finished (completed_date, actual_duration, final_delay_days).
    Raises an error if any leakage field is accidentally included.
    """
    leaked = [f for f in leakage_fields if f in feature_list]
    if leaked:
        raise ValueError(
            f"Data leakage detected: {leaked} must not be used as input "
            "features — they are only used to construct the target label."
        )


def build_preprocessor(numeric_features: list, categorical_features: list) -> ColumnTransformer:
    """
    Build a ColumnTransformer that:
      - Imputes missing numeric values with the median, then scales them.
      - Imputes missing categorical values with a constant "missing"
        label, then one-hot encodes them.

    Used as the first step inside each model's Pipeline so imputers,
    scalers, and encoders are always fit only on training data.
    """
    transformers = []

    if numeric_features:
        numeric_pipeline = Pipeline(steps=[
            ("imputer", SimpleImputer(strategy="median")),
            ("scaler", StandardScaler()),
        ])
        transformers.append(("numeric", numeric_pipeline, numeric_features))

    if categorical_features:
        categorical_pipeline = Pipeline(steps=[
            ("imputer", SimpleImputer(strategy="constant", fill_value="missing")),
            ("encoder", OneHotEncoder(handle_unknown="ignore")),
        ])
        transformers.append(("categorical", categorical_pipeline, categorical_features))

    return ColumnTransformer(transformers=transformers)


def split_features_target(df: pd.DataFrame, features: list, target: str = None):
    """
    Split a dataframe into X (features) and y (target) for one task.
    Bottleneck Detection has no target (unsupervised) -> y is None.
    """
    X = df[features].copy()
    y = df[target].copy() if target else None
    return X, y


def train_test_split_data(X, y, stratify: bool = True):
    """
    Split X, y into train/test sets. Stratification keeps class balance
    in both sets, which matters for the imbalanced delay/risk labels.
    """
    stratify_arg = y if stratify else None
    X_train, X_test, y_train, y_test = train_test_split(
        X, y,
        test_size=TEST_SIZE,
        random_state=RANDOM_STATE,
        stratify=stratify_arg,
    )
    return X_train, X_test, y_train, y_test
