"""
model.py
========
Wraps scikit-learn's IsolationForest with the extra behaviour the
Bottleneck Detection use case needs:

    - Training on the preprocessed feature matrix.
    - Producing an intuitive "bottleneck_score" (higher = more
      anomalous / more likely a bottleneck) instead of scikit-learn's
      raw decision_function output (where LOWER = more anomalous,
      which is a common source of confusion).
    - A binary is_bottleneck flag (1 = flagged, 0 = normal), derived
      straight from IsolationForest's own predict() so it stays
      consistent with the "contamination" rate set in config.py.
    - save()/load() so the trained model can be reused without
      retraining every time main.py runs.

WHY ISOLATION FOREST (for the write-up / exam question):
    There is no labeled "this issue was a bottleneck" ground truth in
    the Data Requirements document, so this is an unsupervised problem.
    Isolation Forest isolates anomalies by randomly partitioning the
    feature space — anomalies (unusual combinations of cycle time,
    rework, dependency load, etc.) require FEWER random splits to
    isolate than normal issues, which is exactly the "an issue that
    behaves very differently from the rest of the backlog" intuition
    we want for bottleneck detection.
"""

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest

from config import ISOLATION_FOREST_PARAMS, MODEL_PATH


class BottleneckDetector:
    """Thin, purpose-built wrapper around sklearn's IsolationForest."""

    def __init__(self, params: dict = None):
        # Allow overriding config.py defaults at call time (useful for
        # future hyperparameter tuning scripts, mirroring the
        # tune_delay.py / delay_prediction.py pattern used elsewhere
        # in ScaleFlow).
        self.params = params or ISOLATION_FOREST_PARAMS
        self.model = IsolationForest(**self.params)
        self._is_fitted = False

    def fit(self, X: pd.DataFrame) -> "BottleneckDetector":
        """Train the Isolation Forest on the preprocessed feature matrix X."""
        self.model.fit(X)
        self._is_fitted = True
        return self

    def _check_fitted(self):
        if not self._is_fitted:
            raise RuntimeError(
                "BottleneckDetector.fit() must be called (or a saved model "
                "loaded) before scoring/predicting."
            )

    def score(self, X: pd.DataFrame) -> np.ndarray:
        """
        Return a human-friendly anomaly score per row, where a
        HIGHER value means MORE anomalous (more likely a bottleneck).

        sklearn's decision_function is the opposite (lower = more
        anomalous), so we negate it here once, in exactly one place,
        so every downstream consumer (evaluate.py, main.py, notebooks)
        can just say "bigger score = bigger risk" without re-deriving
        the sign flip themselves.
        """
        self._check_fitted()
        raw_decision = self.model.decision_function(X)   # low = anomalous
        bottleneck_score = -raw_decision                  # flip: high = anomalous
        return bottleneck_score

    def predict_labels(self, X: pd.DataFrame) -> np.ndarray:
        """
        Return the binary flag for each row using IsolationForest's own
        predict() (-1 = anomaly, 1 = normal), remapped to the more
        readable convention: 1 = bottleneck, 0 = normal.
        """
        self._check_fitted()
        raw_labels = self.model.predict(X)                # -1 = anomaly, 1 = normal
        is_bottleneck = np.where(raw_labels == -1, 1, 0)
        return is_bottleneck

    def score_and_label(self, X: pd.DataFrame) -> pd.DataFrame:
        """
        Convenience method returning both the continuous score and the
        binary label side by side, ready to be attached to a results
        DataFrame.
        """
        return pd.DataFrame(
            {
                "bottleneck_score": self.score(X),
                "is_bottleneck": self.predict_labels(X),
            },
            index=X.index,
        )

    def save(self, path: str = MODEL_PATH) -> None:
        """Persist the trained model to disk with joblib."""
        joblib.dump(self, path)

    @staticmethod
    def load(path: str = MODEL_PATH) -> "BottleneckDetector":
        """Load a previously-trained BottleneckDetector from disk."""
        return joblib.load(path)
