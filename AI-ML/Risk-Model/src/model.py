from sklearn.ensemble import (
    GradientBoostingClassifier,
    RandomForestClassifier,
)
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.svm import SVC


def build_models(preprocessor):
    models = {
        "Logistic Regression": Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                (
                    "classifier",
                    LogisticRegression(
                        C=1.0,
                        max_iter=3000,
                        class_weight="balanced",
                        random_state=42,
                    ),
                ),
            ]
        ),

        "Logistic Regression C=0.1": Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                (
                    "classifier",
                    LogisticRegression(
                        C=0.1,
                        max_iter=3000,
                        class_weight="balanced",
                        random_state=42,
                    ),
                ),
            ]
        ),

        "Logistic Regression C=2": Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                (
                    "classifier",
                    LogisticRegression(
                        C=2.0,
                        max_iter=3000,
                        class_weight="balanced",
                        random_state=42,
                    ),
                ),
            ]
        ),

        "Logistic Regression C=5": Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                (
                    "classifier",
                    LogisticRegression(
                        C=5.0,
                        max_iter=3000,
                        class_weight="balanced",
                        random_state=42,
                    ),
                ),
            ]
        ),

        "SVM Linear": Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                (
                    "classifier",
                    SVC(
                        kernel="linear",
                        C=1.0,
                        class_weight="balanced",
                        probability=True,
                        random_state=42,
                    ),
                ),
            ]
        ),

        "SVM RBF": Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                (
                    "classifier",
                    SVC(
                        kernel="rbf",
                        C=1.0,
                        class_weight="balanced",
                        probability=True,
                        random_state=42,
                    ),
                ),
            ]
        ),

        "Gradient Boosting": Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                (
                    "classifier",
                    GradientBoostingClassifier(
                        n_estimators=200,
                        learning_rate=0.05,
                        max_depth=3,
                        random_state=42,
                    ),
                ),
            ]
        ),

        "Random Forest": Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                (
                    "classifier",
                    RandomForestClassifier(
                        n_estimators=600,
                        max_depth=None,
                        min_samples_leaf=2,
                        class_weight="balanced",
                        random_state=42,
                        n_jobs=-1,
                    ),
                ),
            ]
        ),
    }

    return models