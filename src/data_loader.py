"""
data_loader.py
===============
Responsible for ONE thing only: getting the raw Jira "itemlet" dataset
off disk and into a pandas DataFrame that the rest of the pipeline can
trust (right columns present, right dtypes, nothing silently missing).

Splitting this out from preprocessing keeps "I/O and column
selection" separate from "cleaning and transformation" — easier to
test and easier to swap out later (e.g. if the data source becomes a
database query instead of a CSV).
"""

import os
import pandas as pd

from config import DATA_PATH, ID_COLUMNS, BOTTLENECK_FEATURES


def load_raw_dataset(path: str = DATA_PATH) -> pd.DataFrame:
    """
    Load the raw itemlet CSV into a DataFrame.

    low_memory=False forces pandas to read the whole file before
    guessing column dtypes, which avoids the "mixed types" warning
    that happens on a 700k+ row file with sparsely-populated columns
    (e.g. sprint_name, severity_value).
    """
    if not os.path.exists(path):
        raise FileNotFoundError(
            f"Dataset not found at '{path}'. "
            f"Place 'itemlet_dataset.csv' inside the 'data/' folder "
            f"or update DATA_PATH in config.py."
        )

    df = pd.read_csv(path, low_memory=False)
    return df


def select_model_columns(df: pd.DataFrame) -> pd.DataFrame:
    """
    Keep only the columns the Bottleneck Detection model actually needs:
    the human-readable identifier columns (for reporting) plus the
    curated bottleneck feature set (for modeling).

    Raises a clear error early if a required column is missing, instead
    of letting a cryptic KeyError surface deep inside preprocessing.
    """
    required_columns = ID_COLUMNS + BOTTLENECK_FEATURES
    missing = [col for col in required_columns if col not in df.columns]
    if missing:
        raise KeyError(
            f"The following required columns are missing from the dataset: {missing}. "
            f"Check config.py (BOTTLENECK_FEATURES / ID_COLUMNS) against the CSV header."
        )

    # .copy() avoids a SettingWithCopyWarning later when we mutate this slice.
    return df[required_columns].copy()


def load_model_ready_dataframe(path: str = DATA_PATH) -> pd.DataFrame:
    """
    Convenience wrapper: raw load + column selection in one call.
    This is the function main.py actually calls.
    """
    raw_df = load_raw_dataset(path)
    trimmed_df = select_model_columns(raw_df)
    return trimmed_df
