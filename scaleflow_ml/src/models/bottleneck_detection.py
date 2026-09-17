"""
ScaleFlow AI/ML Module - Bottleneck Detection Model
--------------------------------------------------------
Model Approach document, Section 6.

Problem : Identify tasks, dependencies, or workload situations that may
          be slowing the project down — "where is the project getting
          stuck?" rather than "will this task be late?"
ML Type : Anomaly Detection (unsupervised)
Model   : Isolation Forest

No labeled bottleneck dataset currently exists, so this model is
trained without a target column. It flags unusual task/dependency/
workload behavior as a potential bottleneck.
"""

from sklearn.ensemble import IsolationForest
from sklearn.pipeline import Pipeline

from src.preprocessing import build_preprocessor
from src.features import BOTTLENECK_NUMERIC_FEATURES, BOTTLENECK_CATEGORICAL_FEATURES
from config import RANDOM_STATE, BOTTLENECK_CONTAMINATION


def build_bottleneck_model() -> Pipeline:
    """
    Build the full Bottleneck Detection pipeline:
    preprocessing -> Isolation Forest.

    `contamination` is the expected proportion of tasks/dependencies
    that behave like bottlenecks; it is a starting assumption
    (config.BOTTLENECK_CONTAMINATION) to be refined once project
    managers validate the flagged cases (Model Approach, Section 6).
    """
    preprocessor = build_preprocessor(BOTTLENECK_NUMERIC_FEATURES, BOTTLENECK_CATEGORICAL_FEATURES)

    detector = IsolationForest(
        n_estimators=300,
        contamination=BOTTLENECK_CONTAMINATION,
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )

    pipeline = Pipeline(steps=[
        ("preprocessing", preprocessor),
        ("detector", detector),
    ])

    return pipeline


# Grid for later hyperparameter tuning (training.tune_hyperparameters)
BOTTLENECK_HYPERPARAMETER_GRID = {
    "detector__n_estimators": [150, 300, 500],
    "detector__contamination": [0.05, 0.1, 0.15],
}
