from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier


def train_models(
    X_train,
    y_train,
):
    """
    Train baseline classification models for project health.
    """

    print("\n=== TRAINING HEALTH MODELS ===")

    # Train Logistic Regression as a simple interpretable baseline.
    logistic_model = LogisticRegression(
        max_iter=1000,
        class_weight="balanced",
        random_state=42,
    )

    logistic_model.fit(
        X_train,
        y_train,
    )

    print("Logistic Regression trained successfully.")

    # Train Random Forest to capture nonlinear relationships.
    random_forest_model = RandomForestClassifier(
        n_estimators=300,
        max_depth=12,
        min_samples_leaf=3,
        class_weight="balanced",
        random_state=42,
        n_jobs=-1,
    )

    random_forest_model.fit(
        X_train,
        y_train,
    )

    print("Random Forest trained successfully.")

    return {
        "logistic_regression": logistic_model,
        "random_forest": random_forest_model,
    }