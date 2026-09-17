"""
ScaleFlow AI/ML Module - Project Performance / Health Analysis Model
-------------------------------------------------------------------------
Model Approach document, Section 7.

Problem : Estimate the overall condition of a project and identify
          whether its performance is improving or deteriorating.
ML Type : Regression
Model   : Random Forest Regressor
Status  : Phase 2 — deferred (Model Approach, Section 11). A clearly
          defined numerical health target is required before this
          model can be trained; that target must not be fabricated.
          The structure below is prepared so training can start as
          soon as historical project-health scores are available.
"""

from sklearn.ensemble import RandomForestRegressor
from sklearn.pipeline import Pipeline

from src.preprocessing import build_preprocessor
from src.features import PERFORMANCE_NUMERIC_FEATURES, PERFORMANCE_CATEGORICAL_FEATURES
from config import RANDOM_STATE


def build_performance_model() -> Pipeline:
    """
    Build the full Project Performance / Health Analysis pipeline:
    preprocessing -> Random Forest Regressor.

    Do not call this in production training runs until a real
    `health_score` target exists (see module docstring).
    """
    preprocessor = build_preprocessor(PERFORMANCE_NUMERIC_FEATURES, PERFORMANCE_CATEGORICAL_FEATURES)

    regressor = RandomForestRegressor(
        n_estimators=300,
        max_depth=None,
        min_samples_leaf=2,
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )

    pipeline = Pipeline(steps=[
        ("preprocessing", preprocessor),
        ("regressor", regressor),
    ])

    return pipeline


# Grid for later hyperparameter tuning (training.tune_hyperparameters)
PERFORMANCE_HYPERPARAMETER_GRID = {
    "regressor__n_estimators": [200, 300, 500],
    "regressor__max_depth": [None, 8, 12, 20],
    "regressor__min_samples_leaf": [1, 2, 4],
}
