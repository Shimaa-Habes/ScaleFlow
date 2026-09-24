"""
cleaning.py
-----------
Step 2: turn the raw, messy dataframe into a clean one:
 - fix/standardize text
 - drop broken or duplicate rows
 - compute the actual target columns (resolution_days, duration_class)
"""

import re

import numpy as np
import pandas as pd

from .config import DROP_CREATED_BEFORE, DURATION_CUTS_DAYS, TEXT_MAX_CHARS

# Regex patterns used by clean_text() below. Pre-compiling them once (instead of
# inside the function) is faster because they're reused for every single row.
URL_RE = re.compile(r"https?://\S+|www\.\S+")            # matches web links
IP_RE = re.compile(r"\b\d{1,3}(?:\.\d{1,3}){3}\b")        # matches IPv4 addresses, e.g. 192.168.0.1
HEX_RE = re.compile(r"\b(?=[0-9a-f]*\d)[0-9a-f]{7,40}\b")  # matches hex hashes/commit IDs (must contain a digit)
NUM_RE = re.compile(r"\d+")                                # matches any run of digits
NONWORD_RE = re.compile(r"[^\w\s]")                        # matches punctuation/symbols
SPACE_RE = re.compile(r"\s+")                               # matches runs of whitespace


def clean_text(value, max_chars=TEXT_MAX_CHARS):
    """
    Normalize one piece of free text (a Summary or Description) so the model
    learns from the *content* of a ticket instead of memorizing random noise
    like specific URLs, IPs, hashes or numbers.
    Steps: truncate -> lowercase -> mask URLs/IPs/hashes/numbers with a
    placeholder token -> strip punctuation -> collapse repeated spaces.
    """
    text = str(value)[:max_chars].lower()
    text = URL_RE.sub(" urltoken ", text)
    text = IP_RE.sub(" iptoken ", text)
    text = HEX_RE.sub(" hashtoken ", text)
    text = NUM_RE.sub(" numtoken ", text)
    text = NONWORD_RE.sub(" ", text)
    return SPACE_RE.sub(" ", text).strip()


def normalize_labels(value):
    """
    Turn a raw "Labels" cell like "HR, Kicker,  HR" into a clean, de-duplicated,
    alphabetically sorted, space-separated string: "hr kicker".
    Sorting + de-duplicating means "HR,Kicker" and "Kicker,HR" become identical,
    so the model treats them as the same label set.
    """
    parts = [p.strip().lower().replace(" ", "_").replace("-", "_") for p in str(value).split(",") if p.strip()]
    return " ".join(sorted(set(parts))) if parts else "none"


def clean_data(df):
    """
    Apply all row-level cleaning rules and compute the target columns.
    Returns a brand-new, cleaned dataframe (the input `df` is not modified).
    """
    out = df.copy()

    # Strip leading/trailing whitespace from every text column.
    for column in out.select_dtypes(exclude=["number", "datetime"]).columns:
        out[column] = out[column].astype("string").str.strip()

    # "Status" is dropped if every row has the same value (e.g. all "Done") -
    # a column with only one possible value carries no information for the model.
    out = out.drop(columns=[c for c in ["Status"] if c in out.columns and out[c].nunique() <= 1])

    # Drop rows with missing dates, or where Resolved happened before Created (impossible).
    out = out.dropna(subset=["Created", "Resolved"])
    out = out[out["Resolved"] >= out["Created"]]

    # Drop old outlier tickets (see config.DROP_CREATED_BEFORE).
    out = out[out["Created"] >= pd.Timestamp(DROP_CREATED_BEFORE)]

    # Remove exact duplicate rows, then duplicate (Summary, Created) pairs
    # (same ticket logged twice with slightly different other fields).
    out = out.drop_duplicates().drop_duplicates(subset=["Summary", "Created"])

    out["Priority"] = out["Priority"].fillna("Unknown").str.title()
    out["Summary"] = out["Summary"].fillna("")
    out["Description"] = out["Description"].fillna("")
    out["Labels"] = out["Labels"].fillna("").map(normalize_labels)

    # The actual target: how many days between creation and resolution.
    out["resolution_days"] = (out["Resolved"] - out["Created"]).dt.total_seconds() / 86400

    # np.digitize buckets each resolution_days value into a class index based on
    # DURATION_CUTS_DAYS = [30, 365]. right=True means the cut value itself belongs
    # to the LOWER bucket (e.g. exactly 30 days -> "Fast", not "Medium").
    # Result: 0 = Fast (<=30d), 1 = Medium (31-365d), 2 = Slow (>365d).
    out["duration_class"] = np.digitize(out["resolution_days"], DURATION_CUTS_DAYS, right=True).astype(int)

    return out.reset_index(drop=True)
