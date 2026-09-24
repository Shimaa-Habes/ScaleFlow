"""
features.py
------------
Step 4: turn each raw ticket (Summary, Description, Labels, Priority, Created)
into the numeric/text columns the model actually trains on.

Important: build_features() is also what predict.py calls on brand-new,
unseen tickets - so this file has to work from ONLY the raw columns,
never from anything computed later in the pipeline (like duration_class).
"""

import numpy as np
import pandas as pd

from .cleaning import clean_text, normalize_labels
from .config import display

EPOCH = pd.Timestamp("1970-01-01")  # reference date used to turn "Created" into a plain number of days

# Numeric features computed for every ticket.
NUMERIC_FEATURES = [
    "created_days", "created_year", "created_month", "created_dow", "created_hour", "is_weekend",
    "summary_len", "desc_len", "desc_words", "n_labels",
    "has_url", "has_code", "has_module_path", "has_question", "desc_equals_summary",
]

# Full column list fed into the model: 1 text column, 1 labels column,
# 1 categorical column (Priority), then all the numeric features above.
FEATURE_COLUMNS = ["text", "labels_clean", "Priority"] + NUMERIC_FEATURES


def build_features(df):
    """
    Row-wise feature engineering from the raw columns
    Summary, Description, Labels, Priority, Created.
    Returns a dataframe with exactly the FEATURE_COLUMNS, ready for the
    preprocessing pipelines in pipelines.py.
    """
    feats = pd.DataFrame(index=df.index)
    summary = df["Summary"].fillna("").astype(str)
    description = df["Description"].fillna("").astype(str)
    created = pd.to_datetime(df["Created"])
    labels = df["Labels"].fillna("").map(normalize_labels)

    # Combine summary + description into one cleaned text blob (see clean_text in cleaning.py).
    feats["text"] = (summary + " . " + description).map(clean_text)
    feats["labels_clean"] = labels
    feats["Priority"] = df["Priority"].fillna("Unknown").astype(str).str.title()

    # --- date-based features ---
    feats["created_days"] = (created - EPOCH).dt.total_seconds() / 86400  # days since epoch (captures overall time trend)
    feats["created_year"] = created.dt.year
    feats["created_month"] = created.dt.month
    feats["created_dow"] = created.dt.dayofweek       # 0=Monday ... 6=Sunday
    feats["created_hour"] = created.dt.hour
    feats["is_weekend"] = (created.dt.dayofweek >= 5).astype(int)

    # --- text-shape features ---
    # log1p (log(1+x)) is used instead of raw length so extremely long
    # descriptions don't dominate the feature's scale.
    feats["summary_len"] = np.log1p(summary.str.len())
    feats["desc_len"] = np.log1p(description.str.len())
    feats["desc_words"] = np.log1p(description.str.split().str.len().fillna(0))
    feats["n_labels"] = labels.str.split().str.len()

    # --- simple content flags (1 = present, 0 = absent) ---
    feats["has_url"] = description.str.contains(r"https?://", regex=True).astype(int)
    # "has_code" looks for signs of a pasted stack trace / code block / error log.
    feats["has_code"] = description.str.contains(r"\{code|```|Traceback|Exception|\bat [\w.]+\(", regex=True).astype(int)
    # "has_module_path" catches summaries like "HR > Leaves > Half leave report" (a breadcrumb-style path).
    feats["has_module_path"] = summary.str.contains(r"\s>\s", regex=True).astype(int)
    feats["has_question"] = (summary + description).str.contains(r"\?", regex=True).astype(int)
    feats["desc_equals_summary"] = (summary.str.strip() == description.str.strip()).astype(int)

    return feats[FEATURE_COLUMNS]


def build_feature_matrix(clean_df):
    """Convenience wrapper: build X (features) and y (target) from the cleaned dataframe."""
    X = build_features(clean_df)
    y = clean_df["duration_class"]
    display(X.head(3))
    print("Feature matrix:", X.shape)
    return X, y
