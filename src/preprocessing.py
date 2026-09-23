"""
preprocessing.py
=================
Turns the raw feature columns into a clean numeric matrix that
Isolation Forest can train on, and bundles the fitted imputer + scaler
together so the EXACT SAME transformation can be replayed later on
new data (at inference time, after the model has been saved/loaded).

Why a class instead of loose functions:
    - We need to persist "state" (the median values learned for
      imputation, the mean/std learned for scaling) between training
      and future predictions. A small class + joblib.dump/load is the
      cleanest way to keep that state attached to one object.
"""

import joblib
import pandas as pd
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler

from config import (
    BOTTLENECK_FEATURES,
    BOOLEAN_FEATURES,
    IMPUTATION_STRATEGY,
    PREPROCESSOR_PATH,
)


class BottleneckPreprocessor:
    """
    Fit-once, reuse-forever preprocessing pipeline for the Bottleneck
    Detection feature set.

    Steps applied, in order:
        1. Cast boolean columns (True/False) to integers (1/0), because
           scikit-learn estimators require numeric input.
        2. Median-impute any missing numeric values (cycle time, total
           days, issue_age_days, worklog_total can be NaN for issues
           that are still open / unresolved).
        3. Standardize all features (mean 0, std 1). Isolation Forest
           itself is scale-invariant (it splits on raw thresholds), but
           we scale anyway so that the resulting feature space is
           consistent if we later reuse it for distance-based analysis
           or visualization, and so all features contribute comparably
           if the team experiments with other anomaly detectors.
    """

    def __init__(self):
        self.imputer = SimpleImputer(strategy=IMPUTATION_STRATEGY)
        self.scaler = StandardScaler()
        self.feature_names = BOTTLENECK_FEATURES
        self._is_fitted = False

    def _cast_booleans(self, df: pd.DataFrame) -> pd.DataFrame:
        """Convert True/False boolean columns to 1/0 integers in place."""
        df = df.copy()
        for col in BOOLEAN_FEATURES:
            if col in df.columns:
                df[col] = df[col].astype(int)
        return df

    def fit_transform(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Learn imputation medians + scaling parameters from the TRAINING
        data, then apply them and return the transformed feature matrix.
        """
        features_df = self._cast_booleans(df[self.feature_names])

        # SimpleImputer.fit_transform returns a numpy array — we immediately
        # wrap it back into a DataFrame so downstream code can keep using
        # column names instead of raw positional indices.
        imputed = self.imputer.fit_transform(features_df)
        scaled = self.scaler.fit_transform(imputed)

        self._is_fitted = True
        return pd.DataFrame(scaled, columns=self.feature_names, index=df.index)

    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Apply an ALREADY-FITTED imputer/scaler to new data. Used for
        inference runs after the preprocessor has been loaded from disk.
        """
        if not self._is_fitted:
            raise RuntimeError(
                "BottleneckPreprocessor.transform() called before fit_transform(). "
                "Fit the preprocessor on training data first, or load a saved one."
            )

        features_df = self._cast_booleans(df[self.feature_names])
        imputed = self.imputer.transform(features_df)
        scaled = self.scaler.transform(imputed)
        return pd.DataFrame(scaled, columns=self.feature_names, index=df.index)

    def save(self, path: str = PREPROCESSOR_PATH) -> None:
        """Persist the fitted imputer + scaler + feature list to disk."""
        joblib.dump(self, path)

    @staticmethod
    def load(path: str = PREPROCESSOR_PATH) -> "BottleneckPreprocessor":
        """Load a previously-fitted preprocessor back into memory."""
        return joblib.load(path)
