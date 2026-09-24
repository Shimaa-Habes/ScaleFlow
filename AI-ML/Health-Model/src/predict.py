from pathlib import Path

import joblib
import pandas as pd


MODEL_DIR = (
    Path(__file__).resolve().parents[1]
    / "models"
)


def load_health_model():
    """
    Load the trained Random Forest health model
    and its preprocessing artifacts.
    """

    # Load the trained classification model.
    model = joblib.load(
        MODEL_DIR / "health_random_forest.joblib"
    )

    # Load the imputer used during training.
    imputer = joblib.load(
        MODEL_DIR / "health_imputer.joblib"
    )

    # Load the scaler used during training.
    scaler = joblib.load(
        MODEL_DIR / "health_scaler.joblib"
    )

    # Load the exact feature order used during training.
    feature_names = joblib.load(
        MODEL_DIR / "health_feature_names.joblib"
    )

    return (
        model,
        imputer,
        scaler,
        feature_names,
    )


def calculate_health_score(
    failure_probability: float,
) -> float:
    """
    Convert failure probability into a 0-100 health score.

    Higher health score means better project health.
    """

    # Convert failure probability into a health score.
    health_score = (
        1.0 - failure_probability
    ) * 100.0

    # Keep the score inside the 0-100 range.
    health_score = max(
        0.0,
        min(100.0, health_score),
    )

    return round(
        health_score,
        2,
    )


def get_health_status(
    health_score: float,
) -> str:
    """
    Convert the health score into a user-facing status.
    """

    # Healthy projects have a high health score.
    if health_score >= 80:
        return "Healthy"

    # Projects in the middle range need attention.
    if health_score >= 50:
        return "Needs Attention"

    # Low scores indicate critical project health.
    return "Critical"


def predict_health(
    project_features: dict,
) -> dict:
    """
    Predict project health from project-level features.
    """

    (
        model,
        imputer,
        scaler,
        feature_names,
    ) = load_health_model()

    # Create a DataFrame containing the input project.
    input_data = pd.DataFrame(
        [project_features]
    )

    # Make sure the input follows the exact training feature order.
    input_data = input_data.reindex(
        columns=feature_names
    )

    # Convert values to numeric values.
    input_data = input_data.apply(
        pd.to_numeric,
        errors="coerce",
    )

    # Apply the same missing-value handling used during training.
    input_imputed = imputer.transform(
        input_data
    )

    # Apply the same scaling used during training.
    input_scaled = scaler.transform(
        input_imputed
    )

    # Get the probability that the project will exceed its budget.
    failure_probability = model.predict_proba(
        input_scaled
    )[0][1]

    # Convert failure probability into health score.
    health_score = calculate_health_score(
        failure_probability
    )

    # Convert health score into a readable status.
    status = get_health_status(
        health_score
    )

    return {
        "health_score": health_score,
        "status": status,
        "failure_probability": round(
            float(failure_probability),
            4,
        ),
    }