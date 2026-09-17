"""
ScaleFlow AI/ML Module - Task Delay Prediction Model
---------------------------------------------------------
Model Approach document, Section 4.

Problem : Predict whether a task will be delayed before it is completed.
ML Type : Binary Classification
Model   : Random Forest Classifier
"""

from sklearn.ensemble import RandomForestClassifier
from sklearn.pipeline import Pipeline

from src.preprocessing import build_preprocessor
from src.features import DELAY_NUMERIC_FEATURES, DELAY_CATEGORICAL_FEATURES
from config import RANDOM_STATE


def build_delay_model() -> Pipeline:
    """
    Build the full Task Delay Prediction pipeline:
    preprocessing -> Random Forest Classifier.

    class_weight="balanced" is used because delayed tasks are typically
    the minority class in real project data, and recall on the delayed
    class matters more than raw accuracy (Model Approach, Section 4).
    """
    preprocessor = build_preprocessor(DELAY_NUMERIC_FEATURES, DELAY_CATEGORICAL_FEATURES)

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


# Grid for later hyperparameter tuning (training.tune_hyperparameters)
DELAY_HYPERPARAMETER_GRID = {
    "classifier__n_estimators": [200, 300, 500],
    "classifier__max_depth": [None, 8, 12, 20],
    "classifier__min_samples_leaf": [1, 2, 4],
}
