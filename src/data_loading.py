"""
data_loading.py
----------------
Step 1: load the raw CSV and produce a "data quality" summary table
(missing values, duplicates, weird dates, etc.) so we know what
cleaning is actually needed before we start cleaning.

NOTE: the original notebook also converted an .xlsx file to .csv here.
That step has been removed on purpose because we already have the CSV
file (Jira_task_dataset.csv) - we just read it directly.
"""

import pandas as pd

from .config import CSV_PATH, DROP_CREATED_BEFORE, TEXT_MAX_CHARS, display


def load_raw_data(csv_path=CSV_PATH):
    """
    Read the raw Jira CSV export.

    keep_default_na=False + na_values=[""]  -> only a truly empty cell counts as
        missing. Without this, pandas would also treat literal text like the
        words "None" or "NA" inside a ticket description as missing data.
    encoding="utf-8-sig"                    -> matches how the CSV was saved,
        so special characters and the invisible BOM marker at the start of
        the file are handled correctly.
    parse_dates=[...]                       -> turns the "Created"/"Resolved"
        text columns straight into real datetime objects.
    """
    raw_df = pd.read_csv(
        csv_path,
        encoding="utf-8-sig",
        keep_default_na=False,
        na_values=[""],
        parse_dates=["Created", "Resolved"],
    )
    print("Shape:", raw_df.shape)
    display(raw_df.head())
    display(raw_df.dtypes.to_frame("dtype"))
    return raw_df


def quality_overview(df):
    """
    Build a one-column summary of data-quality issues in `df`.
    Each entry below answers one question about the data, e.g.
    "how many rows are exact duplicates?" or "how many tickets were
    resolved before they were even created (a logical error)?".
    Used once on the raw data and again after cleaning, so we can see
    the "before vs after" side by side.
    """
    # Every column that isn't a number or a date is treated as "text" here.
    text_cols = df.select_dtypes(exclude=["number", "datetime"]).columns

    return pd.Series(
        {
            "rows": len(df),
            "missing_cells": int(df.isna().sum().sum()),
            "missing_labels": int(df["Labels"].isna().sum()),
            "exact_duplicate_rows": int(df.duplicated().sum()),
            "duplicate_summary_and_created": int(df.duplicated(subset=["Summary", "Created"]).sum()),
            "status_values": ", ".join(sorted(df["Status"].astype(str).unique())),
            # Resolved before Created is a logical impossibility -> flags broken rows.
            "resolved_before_created": int((df["Resolved"] < df["Created"]).sum()),
            # Tickets "resolved" within 15 minutes of creation are usually bulk-closed/auto-closed, not real fixes.
            "resolved_within_15_min": int(((df["Resolved"] - df["Created"]).dt.total_seconds() < 900).sum()),
            "created_before_" + DROP_CREATED_BEFORE: int((df["Created"] < pd.Timestamp(DROP_CREATED_BEFORE)).sum()),
            # Cells that have leading/trailing spaces we'll want to strip.
            "text_cells_with_extra_whitespace": int(
                sum(
                    (df[c].dropna().astype(str) != df[c].dropna().astype(str).str.strip()).sum()
                    for c in text_cols
                )
            ),
            "description_equals_summary": int((df["Description"] == df["Summary"]).sum()),
            "descriptions_over_%d_chars" % TEXT_MAX_CHARS: int(
                (df["Description"].fillna("").str.len() > TEXT_MAX_CHARS).sum()
            ),
        },
        name="value",
    )
