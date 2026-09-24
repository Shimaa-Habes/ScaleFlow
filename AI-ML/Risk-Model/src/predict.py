from pathlib import Path

import joblib
import pandas as pd


MODEL_PATH = (
    Path(__file__).resolve().parents[1]
    / "models"
    / "risk_model.joblib"
)


RISK_ORDER = {
    "Low": 0,
    "Medium": 1,
    "High": 2,
    "Critical": 3,
}


def load_model():
    if not MODEL_PATH.exists():
        raise FileNotFoundError(
            f"Risk model not found: {MODEL_PATH}"
        )

    return joblib.load(MODEL_PATH)


def calculate_risk_score(probabilities, classes):
    """
    Calculate a continuous risk score from 0 to 100.

    Low      = 0
    Medium   = 33.33
    High     = 66.67
    Critical = 100
    """

    score = 0.0

    for probability, class_name in zip(probabilities, classes):
        level = RISK_ORDER.get(class_name, 0)

        score += (
            float(probability)
            * (level / 3)
            * 100
        )

    return round(score, 2)


def predict_risk(input_data: dict):
    """
    Predict project risk from project features.
    """

    model = load_model()

    input_df = pd.DataFrame([input_data])

    predicted_class = model.predict(input_df)[0]

    probabilities = model.predict_proba(input_df)[0]

    classes = model.classes_

    confidence = float(probabilities.max())

    risk_score = calculate_risk_score(
        probabilities,
        classes
    )

    probability_map = {
        class_name: round(float(probability), 4)
        for class_name, probability in zip(
            classes,
            probabilities
        )
    }

    return {
        "risk_score": risk_score,
        "risk_level": predicted_class,
        "confidence": round(confidence, 4),
        "probabilities": probability_map,
    }