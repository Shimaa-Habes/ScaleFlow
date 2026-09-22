"""
model_selection.py
-------------------
Step 7-9:
 1. compare several off-the-shelf models with cross-validation
 2. tune the hyperparameters of the most promising ones
 3. combine the tuned models into a soft-voting ensemble
 4. pick the single best final model
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.base import clone
from sklearn.calibration import CalibratedClassifierCV
from sklearn.dummy import DummyClassifier
from sklearn.ensemble import (
    ExtraTreesClassifier,
    HistGradientBoostingClassifier,
    RandomForestClassifier,
    VotingClassifier,
)
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import RandomizedSearchCV, cross_validate
from sklearn.neural_network import MLPClassifier
from sklearn.svm import LinearSVC

from .config import FIGURE_DIR, RANDOM_STATE, REPORT_DIR, SEARCH_ITER, SEARCH_SCORING, display
from .pipelines import dense_pipeline, sparse_pipeline

SCORING = {"accuracy": "accuracy", "macro_f1": "f1_macro", "balanced_accuracy": "balanced_accuracy"}


def cv_scores(name, pipeline, X_, y_, cv):
    """Run cross-validation for one pipeline and summarize the scores into one row."""
    scores = cross_validate(pipeline, X_, y_, cv=cv, scoring=SCORING, n_jobs=1)
    return {
        "model": name,
        "accuracy": scores["test_accuracy"].mean(),
        "accuracy_std": scores["test_accuracy"].std(),
        "macro_f1": scores["test_macro_f1"].mean(),
        "balanced_accuracy": scores["test_balanced_accuracy"].mean(),
    }


def compare_models(X_train, y_train, cv):
    """Cross-validate a handful of different model families and rank them by accuracy."""
    candidates = {
        "Majority-class baseline": dense_pipeline(DummyClassifier(strategy="most_frequent")),
        "Logistic Regression": sparse_pipeline(LogisticRegression(C=10, max_iter=5000)),
        # CalibratedClassifierCV wraps the SVM so it can output probabilities
        # (a plain LinearSVC only gives hard class labels, no probabilities).
        "Linear SVM (calibrated)": sparse_pipeline(CalibratedClassifierCV(LinearSVC(C=1.0), cv=3)),
        "Random Forest": dense_pipeline(RandomForestClassifier(n_estimators=400, n_jobs=-1, random_state=RANDOM_STATE)),
        "Extra Trees": dense_pipeline(ExtraTreesClassifier(n_estimators=400, n_jobs=-1, random_state=RANDOM_STATE)),
        "Hist Gradient Boosting": dense_pipeline(HistGradientBoostingClassifier(random_state=RANDOM_STATE)),
        "MLP (64, 32)": dense_pipeline(
            MLPClassifier(hidden_layer_sizes=(64, 32), alpha=1e-2, early_stopping=True, max_iter=800, random_state=RANDOM_STATE),
            scale=True,
        ),
    }

    comparison = (
        pd.DataFrame([cv_scores(name, pipe, X_train, y_train, cv) for name, pipe in candidates.items()])
        .set_index("model")
        .sort_values("accuracy", ascending=False)
    )
    display(comparison.round(3))
    comparison.to_csv(REPORT_DIR / "model_comparison.csv")

    fig, ax = plt.subplots(figsize=(8, 4))
    ordered = comparison.iloc[::-1]
    ax.barh(ordered.index, ordered["accuracy"], xerr=ordered["accuracy_std"])
    ax.axvline(0.9, color="red", linestyle="--", label="0.90")
    ax.set_xlabel("Cross-validated accuracy")
    ax.set_title("Model comparison")
    ax.legend()
    fig.tight_layout()
    fig.savefig(FIGURE_DIR / "model_comparison.png", dpi=150)
    plt.close(fig)

    return comparison, candidates


def tune_models(X_train, y_train, cv):
    """
    Run RandomizedSearchCV (tries random combinations instead of every single
    combination - much faster than a full grid search) for the 3 most
    promising model types, and return the best-fitted version of each.
    """
    search_spaces = {
        "Hist Gradient Boosting": (
            dense_pipeline(HistGradientBoostingClassifier(random_state=RANDOM_STATE)),
            {
                "model__learning_rate": [0.03, 0.05, 0.08, 0.12],
                "model__max_iter": [150, 300, 500],
                "model__max_leaf_nodes": [7, 15, 31],
                "model__min_samples_leaf": [3, 5, 10, 20],
                "model__l2_regularization": [0.0, 0.1, 1.0, 5.0],
                "model__class_weight": [None, "balanced"],
            },
        ),
        "Random Forest": (
            dense_pipeline(RandomForestClassifier(n_jobs=-1, random_state=RANDOM_STATE)),
            {
                "model__n_estimators": [300, 600],
                "model__max_features": ["sqrt", 0.3, 0.5],
                "model__min_samples_leaf": [1, 2, 3, 5],
                "model__max_depth": [None, 12, 20],
                "model__class_weight": [None, "balanced_subsample"],
            },
        ),
        "Logistic Regression": (
            sparse_pipeline(LogisticRegression(max_iter=5000)),
            {"model__C": [0.3, 1, 3, 10, 30, 100], "model__class_weight": [None, "balanced"]},
        ),
    }

    tuned = {}
    tuning_rows = []
    for name, (pipeline, space) in search_spaces.items():
        # Don't ask for more random draws than the number of combinations that actually exist.
        n_iter = min(SEARCH_ITER, int(np.prod([len(v) for v in space.values()])))
        search = RandomizedSearchCV(
            pipeline, space, n_iter=n_iter, scoring=SEARCH_SCORING, cv=cv, n_jobs=1, refit=True, random_state=RANDOM_STATE
        )
        search.fit(X_train, y_train)
        tuned[name] = search.best_estimator_
        tuning_rows.append({"model": name, f"best_cv_{SEARCH_SCORING}": search.best_score_, "best_params": search.best_params_})
        print(f"{name}: best CV {SEARCH_SCORING} = {search.best_score_:.4f}")

    tuning_table = pd.DataFrame(tuning_rows).set_index("model")
    display(tuning_table)
    return tuned, tuning_table


def build_ensemble(tuned):
    """Combine the tuned models into one soft-voting ensemble.
    'soft' voting averages each model's predicted probabilities (rather than
    just counting votes), which usually gives smoother, better-calibrated predictions."""
    return VotingClassifier(
        estimators=[(name.lower().replace(" ", "_"), clone(model)) for name, model in tuned.items()],
        voting="soft",
        n_jobs=1,
    )


def select_best_model(tuned, ensemble, X_train, y_train, cv):
    """Cross-validate the tuned models + the ensemble one more time, and fit
    the single best-scoring one on the full training set."""
    final_candidates = {f"{name} (tuned)": model for name, model in tuned.items()}
    final_candidates["Soft-voting ensemble (tuned)"] = ensemble

    final_comparison = (
        pd.DataFrame([cv_scores(name, model, X_train, y_train, cv) for name, model in final_candidates.items()])
        .set_index("model")
        .sort_values(["accuracy", "macro_f1"], ascending=False)
    )
    display(final_comparison.round(4))
    final_comparison.to_csv(REPORT_DIR / "final_model_comparison.csv")

    best_name = final_comparison.index[0]
    best_model = clone(final_candidates[best_name]).fit(X_train, y_train)
    print("Selected model:", best_name)
    return best_model, best_name, final_candidates, final_comparison
