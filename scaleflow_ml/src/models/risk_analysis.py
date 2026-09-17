"""
ScaleFlow AI/ML Module - Risk Analysis Model
------------------------------------------------
Model Approach document, Section 5.

Problem : Estimate the risk level of a task or project based on its
          current condition (Low / Medium / High).
ML Type : Classification (initial approach)
Model   : Random Forest Classifier

An alternative regression version is included below for the case
where the dataset provides a continuous risk_score (0-100) instead of
discrete risk classes, as explicitly allowed by the AI/ML Data
Requirements document.
"""

from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.pipeline import Pipeline

from src.preprocessing import build_preprocessor
from src.features import RISK_NUMERIC_FEATURES, RISK_CATEGORICAL_FEATURES
from config import RANDOM_STATE


def build_risk_model() -> Pipeline:
    """
    Build the full Risk Analysis pipeline:
    preprocessing -> Random Forest Classifier (Low / Medium / High).
    """
    preprocessor = build_preprocessor(RISK_NUMERIC_FEATURES, RISK_CATEGORICAL_FEATURES)

    classifier = RandomForestClassifier(
        n_estimators=300,
        max_depth=None,
        min_samples_leaf=2,
        class_weight="balanced",
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )

    pipeline = Pipeline(steps=[
        ("preprocessing", preprocessor),
        ("classifier", classifier),
    ])

    return pipeline


def build_risk_score_regressor() -> Pipeline:
    """
    Alternative pipeline for a continuous risk_score (0-100) target,
    for use only if the dataset provides risk_score instead of
    risk_level (Model Approach, Section 5 — Target).
    """
    preprocessor = build_preprocessor(RISK_NUMERIC_FEATURES, RISK_CATEGORICAL_FEATURES)

    regressor = RandomForestRegressor(
        n_estimators=300,
        max_depth=None,
        min_samples_leaf=2,
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )

    return Pipeline(steps=[
        ("preprocessing", preprocessor),
        ("regressor", regressor),
    ])


# Grid for later hyperparameter tuning (training.tune_hyperparameters)
RISK_HYPERPARAMETER_GRID = {
    "classifier__n_estimators": [200, 300, 500],
    "classifier__max_depth": [None, 8, 12, 20],
    "classifier__min_samples_leaf": [1, 2, 4],
}
