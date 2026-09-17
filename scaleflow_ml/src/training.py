"""
ScaleFlow AI/ML Module - Training Utilities
-----------------------------------------------
Reusable functions to train, cross-validate, tune, and persist model
pipelines. Shared across all four ML problems; anomaly detection
(Bottleneck Detection) is unsupervised, so its training/tuning
functions accept X only (no y).
"""

import os
import joblib
from sklearn.model_selection import cross_val_score, GridSearchCV, StratifiedKFold, KFold

from config import RANDOM_STATE, CV_FOLDS, MODELS_DIR


def train_model(pipeline, X_train, y_train=None):
    """
    Fit a model pipeline on the training data.
    y_train is omitted for unsupervised pipelines (Bottleneck Detection).
    """
    if y_train is None:
        pipeline.fit(X_train)
    else:
        pipeline.fit(X_train, y_train)
    return pipeline


def cross_validate_model(pipeline, X, y, scoring: str = "f1_weighted", cv: int = CV_FOLDS):
    """
    Run stratified k-fold cross-validation (classification) and return
    the fold scores. Not applicable to Bottleneck Detection, which has
    no labels to score against.
    """
    skf = StratifiedKFold(n_splits=cv, shuffle=True, random_state=RANDOM_STATE)
    scores = cross_val_score(pipeline, X, y, cv=skf, scoring=scoring, n_jobs=-1)
    return scores


def cross_validate_regressor(pipeline, X, y, scoring: str = "neg_mean_absolute_error", cv: int = CV_FOLDS):
    """K-fold cross-validation for the Performance/Health regressor."""
    kf = KFold(n_splits=cv, shuffle=True, random_state=RANDOM_STATE)
    scores = cross_val_score(pipeline, X, y, cv=kf, scoring=scoring, n_jobs=-1)
    return scores


def tune_hyperparameters(pipeline, param_grid: dict, X_train, y_train,
                          scoring: str = "f1_weighted", cv: int = CV_FOLDS):
    """
    Run a grid search over the given hyperparameter grid.
    Returns the fitted GridSearchCV object (use .best_estimator_ /
    .best_params_ / .best_score_ on the result).
    """
    skf = StratifiedKFold(n_splits=cv, shuffle=True, random_state=RANDOM_STATE)
    search = GridSearchCV(
        estimator=pipeline,
        param_grid=param_grid,
        scoring=scoring,
        cv=skf,
        n_jobs=-1,
        verbose=1,
    )
    search.fit(X_train, y_train)
    return search


def save_model(pipeline, task_name: str, filename: str = None) -> str:
    """Persist a trained pipeline to the artifacts/models directory."""
    os.makedirs(MODELS_DIR, exist_ok=True)
    filename = filename or f"{task_name}_pipeline.joblib"
    file_path = os.path.join(MODELS_DIR, filename)
    joblib.dump(pipeline, file_path)
    return file_path


def load_model(file_path: str):
    """Load a previously trained pipeline from disk."""
    return joblib.load(file_path)
