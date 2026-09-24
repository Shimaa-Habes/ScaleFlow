"""
evaluation.py
-------------
Step 10-11: evaluate the final chosen model properly.
 - metrics + confusion matrix on the held-out test set
 - permutation importance (which features the model actually relies on)
 - a "time-shift" check: train on older tickets, test on newer ones, to see
   if performance holds up on data from the future relative to training
   (a random train/test split can hide this kind of decay).
"""

import json

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.base import clone
from sklearn.inspection import permutation_importance
from sklearn.metrics import (
    accuracy_score,
    balanced_accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    roc_auc_score,
)

from .config import CLASS_NAMES, FIGURE_DIR, RANDOM_STATE, TEST_SIZE, display


def evaluate_on_test_set(best_model, X_test, y_test, X_train, y_train):
    """Compute headline metrics on the held-out test set and save a confusion-matrix chart."""
    y_pred = best_model.predict(X_test)
    y_proba = best_model.predict_proba(X_test)
    majority = int(y_train.mode().iloc[0])  # most common class in the training set

    test_metrics = {
        "accuracy": accuracy_score(y_test, y_pred),
        "balanced_accuracy": balanced_accuracy_score(y_test, y_pred),
        "macro_f1": f1_score(y_test, y_pred, average="macro"),
        "weighted_f1": f1_score(y_test, y_pred, average="weighted"),
        # "one-vs-rest" ROC-AUC averaged across the 3 classes.
        "roc_auc_ovr_macro": roc_auc_score(y_test, y_proba, multi_class="ovr", average="macro"),
        # How often the prediction is at most 1 class away from the truth
        # (e.g. predicting "Medium" when the truth is "Fast" still counts as close).
        "within_one_class_accuracy": float((np.abs(y_test.to_numpy() - y_pred) <= 1).mean()),
        # Baseline: accuracy you'd get by always predicting the majority class. The real model should beat this.
        "majority_baseline_accuracy": float((y_test == majority).mean()),
        "train_accuracy": accuracy_score(y_train, best_model.predict(X_train)),  # sanity check for overfitting
    }
    test_metrics = {k: float(v) for k, v in test_metrics.items()}
    display(pd.Series(test_metrics, name="value").round(4).to_frame())

    report_df = pd.DataFrame(
        classification_report(y_test, y_pred, target_names=CLASS_NAMES, output_dict=True, zero_division=0)
    ).T
    display(report_df.round(3))

    _plot_confusion_matrix(y_test, y_pred)

    return y_pred, y_proba, test_metrics, report_df


def _plot_confusion_matrix(y_test, y_pred):
    """Draw two side-by-side confusion matrices: raw counts, and row-normalized (percentages)."""
    conf = confusion_matrix(y_test, y_pred, labels=[0, 1, 2])
    fig, axes = plt.subplots(1, 2, figsize=(12, 4.5))
    for ax, matrix, title, fmt in [
        (axes[0], conf, "Confusion matrix (counts)", "d"),
        (axes[1], conf / conf.sum(axis=1, keepdims=True), "Confusion matrix (row-normalized)", ".2f"),
    ]:
        ax.imshow(matrix, cmap="Blues")
        ax.set_xticks(range(3), CLASS_NAMES, rotation=20)
        ax.set_yticks(range(3), CLASS_NAMES)
        ax.set_xlabel("Predicted")
        ax.set_ylabel("Actual")
        ax.set_title(title)
        for i in range(3):
            for j in range(3):
                # White text on dark cells, black text on light cells, so numbers stay readable.
                ax.text(j, i, format(matrix[i, j], fmt), ha="center", va="center", color="white" if matrix[i, j] > matrix.max() / 2 else "black")
    fig.tight_layout()
    fig.savefig(FIGURE_DIR / "confusion_matrix.png", dpi=150)
    plt.close(fig)


def permutation_importance_report(best_model, X_test, y_test):
    """
    Permutation importance = shuffle ONE feature column at a time and see how
    much the model's test-set macro-F1 score drops. A big drop means the model
    relies heavily on that feature; almost no drop means the feature barely matters.
    n_repeats=10 shuffles each feature 10 times and averages, for a stabler estimate.
    """
    perm = permutation_importance(best_model, X_test, y_test, scoring="f1_macro", n_repeats=10, random_state=RANDOM_STATE, n_jobs=1)
    importance_df = (
        pd.DataFrame({"feature": X_test.columns, "importance_mean": perm.importances_mean, "importance_std": perm.importances_std})
        .sort_values("importance_mean", ascending=False)
        .reset_index(drop=True)
    )
    display(importance_df.head(12).round(4))

    top = importance_df.head(12).iloc[::-1]  # reverse so the biggest bar is at the top of the chart
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.barh(top["feature"], top["importance_mean"], xerr=top["importance_std"])
    ax.set_xlabel("Drop in test macro-F1 when the feature is shuffled")
    ax.set_title("Permutation importance (top 12)")
    fig.tight_layout()
    fig.savefig(FIGURE_DIR / "permutation_importance.png", dpi=150)
    plt.close(fig)

    return importance_df


def time_shift_check(clean_df, X, y, final_candidates, best_name):
    """
    Instead of a random train/test split, sort tickets by creation date and
    train on the OLDEST 80%, test on the NEWEST 20%. This mimics the real
    situation of predicting future tickets and reveals whether accuracy
    holds up over time (a random split can hide performance decay).
    """
    order = clean_df.sort_values("Created").index
    cut = int(len(order) * (1 - TEST_SIZE))
    train_idx, test_idx = order[:cut], order[cut:]

    time_model = clone(final_candidates[best_name]).fit(X.loc[train_idx], y.loc[train_idx])
    time_pred = time_model.predict(X.loc[test_idx])

    time_metrics = {
        "train_created_until": str(clean_df.loc[train_idx, "Created"].max().date()),
        "test_created_from": str(clean_df.loc[test_idx, "Created"].min().date()),
        "accuracy": float(accuracy_score(y.loc[test_idx], time_pred)),
        "macro_f1": float(f1_score(y.loc[test_idx], time_pred, average="macro")),
        "test_class_shares": y.loc[test_idx].value_counts(normalize=True).sort_index().round(3).to_dict(),
    }
    print(json.dumps(time_metrics, indent=2))
    return time_metrics
