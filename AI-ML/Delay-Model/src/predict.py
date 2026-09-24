"""
predict.py
----------
Step 14: use the SAVED model (not the one still in memory) to predict on
new, unseen tickets. This is the file you'd reuse in a separate script or
service once the model is trained - it doesn't need any of the training code.
"""

import joblib
import pandas as pd

from .config import CLASS_NAMES, MODEL_DIR
from .features import build_features


def load_model(model_path=None):
    """Load the trained pipeline saved by save_artifacts.py."""
    model_path = model_path or (MODEL_DIR / "jira_resolution_class_model.joblib")
    return joblib.load(model_path)


def predict_resolution_class(new_issues, model=None):
    """
    Predict the resolution-time class for new tickets.
    `new_issues` must be a DataFrame with the raw columns:
    Summary, Description, Labels, Priority, Created.
    Returns a DataFrame with the predicted class and one probability
    column per class.
    """
    model = model or load_model()
    features = build_features(new_issues)
    codes = model.predict(features)
    probabilities = model.predict_proba(features)

    result = pd.DataFrame({"predicted_class": [CLASS_NAMES[int(c)] for c in codes]}, index=new_issues.index)
    for position, class_code in enumerate(model.classes_):
        result[f"prob_{CLASS_NAMES[int(class_code)]}"] = probabilities[:, position].round(3)
    return result
