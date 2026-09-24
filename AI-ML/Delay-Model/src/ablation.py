"""
ablation.py
-----------
Step 6: an "ablation study" - repeatedly train the SAME simple model
(Logistic Regression) while progressively adding feature groups, to see
which pieces of information (text, labels, priority, dates) actually
help predict resolution time. This tells a real story ("labels barely
matter, but text and creation time do") instead of just reporting one
final accuracy number.
"""

import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_validate
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

from .config import REPORT_DIR, display
from .features import NUMERIC_FEATURES

# Each entry = (columns used, extra numeric columns used).
ABLATION_SETS = {
    "text only": (["text"], []),
    "text + labels": (["text", "labels_clean"], []),
    "text + labels + priority": (["text", "labels_clean", "Priority"], []),
    "everything except creation time": (
        ["text", "labels_clean", "Priority"],
        [c for c in NUMERIC_FEATURES if not c.startswith("created_") and c != "is_weekend"],
    ),
    "everything (incl. creation time)": (["text", "labels_clean", "Priority"], NUMERIC_FEATURES),
}


def ablation_pipeline(text_cols, numeric_cols, model):
    """Build a small pipeline that only uses the requested feature groups."""
    parts = []
    if "text" in text_cols:
        parts.append(("text", TfidfVectorizer(ngram_range=(1, 2), min_df=2, max_features=20000, sublinear_tf=True, stop_words="english"), "text"))
    if "labels_clean" in text_cols:
        parts.append(("labels", TfidfVectorizer(token_pattern=r"[^ ]+", min_df=1), "labels_clean"))
    if "Priority" in text_cols:
        parts.append(("priority", OneHotEncoder(handle_unknown="ignore"), ["Priority"]))
    if numeric_cols:
        parts.append(("numeric", StandardScaler(), numeric_cols))
    return Pipeline([("prep", ColumnTransformer(parts)), ("model", model)])


def run_ablation(X_train, y_train, cv):
    """Cross-validate each feature-group combination and save the results table."""
    rows = []
    for name, (text_cols, numeric_cols) in ABLATION_SETS.items():
        scores = cross_validate(
            ablation_pipeline(text_cols, numeric_cols, LogisticRegression(C=10, max_iter=5000)),
            X_train, y_train, cv=cv, scoring={"accuracy": "accuracy", "macro_f1": "f1_macro"},
        )
        rows.append({"features": name, "accuracy": scores["test_accuracy"].mean(), "macro_f1": scores["test_macro_f1"].mean()})

    ablation = pd.DataFrame(rows).set_index("features")
    display(ablation.round(3))
    ablation.to_csv(REPORT_DIR / "ablation.csv")
    return ablation
