from pathlib import Path
import json
import numpy as np
import pandas as pd

# ------------------------------------------------------------
# 1. Basic settings
# ------------------------------------------------------------

pd.set_option("display.max_columns", 100)
pd.set_option("display.width", 160)

CHUNK_SIZE = 100_000
INSPECTION_ROWS = 5


# ------------------------------------------------------------
# 2. Find the ScaleFlow AI_ML folder
# ------------------------------------------------------------

def find_ai_ml_dir():
    """Find the AI_ML folder from common ScaleFlow run locations."""

    candidates = []

    # Try the location of this Python file first.
    try:
        script_dir = Path(__file__).resolve().parent
        candidates.extend([
            script_dir,
            script_dir.parent,
            script_dir / "AI_ML",
            script_dir / "ScaleFlow" / "AI_ML",
        ])
    except NameError:
        pass

    # Also try the current working directory.
    current_dir = Path.cwd().resolve()
    candidates.extend([
        current_dir,
        current_dir.parent,
        current_dir / "AI_ML",
        current_dir / "ScaleFlow" / "AI_ML",
    ])

    for candidate in candidates:
        if candidate.name == "AI_ML" and (candidate / "Data").exists():
            return candidate

    raise FileNotFoundError(
        "AI_ML folder was not found. Run this file from the ScaleFlow project "
        "or place it inside AI_ML/Notebooks."
    )


AI_ML_DIR = find_ai_ml_dir()
RAW_DIR = AI_ML_DIR / "Data" / "raw"
PROCESSED_DIR = AI_ML_DIR / "Data" / "processed"
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

# Raw JIRA files
ISSUES_PATH = RAW_DIR / "issues.zip"
LINKS_PATH = RAW_DIR / "issuelinks.zip"
CHANGELOG_PATH = RAW_DIR / "changelog.zip"
COMMENTS_PATH = RAW_DIR / "comments.csv.7z"

# Temporary files
CLEAN_ISSUES_PATH = PROCESSED_DIR / "_clean_issues.csv"
ENRICHED_PATH = PROCESSED_DIR / "_enriched_dataset.csv"

# Final output files
FINAL_DATASET_PATH = PROCESSED_DIR / "final_dataset.csv"
TRAIN_PATH = PROCESSED_DIR / "train.csv"
VALIDATION_PATH = PROCESSED_DIR / "validation.csv"
TEST_PATH = PROCESSED_DIR / "test.csv"
BOTTLENECK_DATASET_PATH = PROCESSED_DIR / "bottleneck_dataset.csv"
MAPPING_PATH = PROCESSED_DIR / "jira_to_scaleflow_mapping.csv"
METADATA_PATH = PROCESSED_DIR / "preprocessing_metadata.json"

print("pandas version:", pd.__version__)
print("AI_ML folder:", AI_ML_DIR)
print("Raw data folder:", RAW_DIR)
print("Processed data folder:", PROCESSED_DIR)
print("Chunk size:", f"{CHUNK_SIZE:,}")


# ------------------------------------------------------------
# 3. Check that the required raw files exist
# ------------------------------------------------------------

raw_files = {
    "Issues": ISSUES_PATH,
    "Issue Links": LINKS_PATH,
    "Changelog": CHANGELOG_PATH,
    "Comments": COMMENTS_PATH,
}

print("\nRaw file inventory:")
for name, path in raw_files.items():
    size_mb = round(path.stat().st_size / (1024 ** 2), 2) if path.exists() else None
    print(f"- {name}: exists={path.exists()}, size_mb={size_mb}")

# Comments are optional for the current structured ML pipeline.
required_files = [ISSUES_PATH, LINKS_PATH, CHANGELOG_PATH]
missing_files = [path.name for path in required_files if not path.exists()]

if missing_files:
    raise FileNotFoundError("Missing required files: " + ", ".join(missing_files))

print("Required structured datasets are available.")


# ------------------------------------------------------------
# 4. Save the JIRA-to-ScaleFlow mapping
# ------------------------------------------------------------

mapping_df = pd.DataFrame({
    "JIRA source": [
        "issues.csv", "issues.csv", "issues.csv", "issues.csv", "issues.csv",
        "issues.csv", "issues.csv", "issuelinks.csv", "issuelinks.csv",
        "changelog.csv", "changelog.csv", "changelog.csv", "comments.csv"
    ],
    "JIRA field": [
        "key", "project.key", "priority.name", "issuetype.name", "issuetype.subtask",
        "created", "resolutiondate", "all link rows", "blocking links",
        "status", "assignee", "priority", "comment text"
    ],
    "ScaleFlow field": [
        "task_key", "project_key", "priority", "issue_type", "is_subtask",
        "created_date", "completed_date", "issue_link_count", "dependency_count",
        "status_change_count", "assignee_change_count", "priority_change_count",
        "future_text_features"
    ],
    "Role": [
        "Identifier", "Feature", "Feature", "Feature", "Feature",
        "Feature / split", "Target source", "Analytical feature", "Analytical feature",
        "Historical feature", "Historical feature", "Leakage check", "Future work"
    ],
})

mapping_df.to_csv(MAPPING_PATH, index=False)
print("\nSaved mapping:", MAPPING_PATH)


# ------------------------------------------------------------
# 5. Inspect a few rows from each structured dataset
# ------------------------------------------------------------

issues_preview = pd.read_csv(
    ISSUES_PATH,
    compression="zip",
    nrows=INSPECTION_ROWS,
    low_memory=False,
)

links_preview = pd.read_csv(
    LINKS_PATH,
    compression="zip",
    nrows=INSPECTION_ROWS,
    low_memory=False,
)

changelog_preview = pd.read_csv(
    CHANGELOG_PATH,
    compression="zip",
    nrows=INSPECTION_ROWS,
    low_memory=False,
)

for name, df in {
    "issues.csv": issues_preview,
    "issuelinks.csv": links_preview,
    "changelog.csv": changelog_preview,
}.items():
    print("\n" + "=" * 80)
    print(name)
    print("Preview shape:", df.shape)
    print(df.head())

    schema = pd.DataFrame({
        "column": df.columns,
        "dtype": df.dtypes.astype(str).values,
        "missing_%": (df.isna().mean() * 100).round(2).values,
    })
    print("\nSchema:")
    print(schema.to_string(index=False))


# ------------------------------------------------------------
# 6. Clean and prepare issues.csv
# ------------------------------------------------------------

ISSUE_COLUMNS = [
    "key",
    "project.key",
    "priority.name",
    "issuetype.name",
    "issuetype.subtask",
    "status.name",
    "resolution.name",
    "created",
    "updated",
    "resolutiondate",
]

if CLEAN_ISSUES_PATH.exists():
    CLEAN_ISSUES_PATH.unlink()

first_write = True
seen_keys = set()
rows_written = 0
rows_removed_as_duplicates = 0

reader = pd.read_csv(
    ISSUES_PATH,
    compression="zip",
    usecols=ISSUE_COLUMNS,
    chunksize=CHUNK_SIZE,
    low_memory=False,
)

for chunk_number, chunk in enumerate(reader, start=1):
    # Rename JIRA columns to simpler ScaleFlow names.
    chunk = chunk.rename(columns={
        "key": "task_key",
        "project.key": "project_key",
        "priority.name": "priority",
        "issuetype.name": "issue_type",
        "issuetype.subtask": "is_subtask",
        "status.name": "status_name",
        "resolution.name": "resolution_name",
        "created": "created_date",
        "updated": "updated_date",
        "resolutiondate": "completed_date",
    })

    # Clean the task key.
    chunk["task_key"] = chunk["task_key"].astype("string").str.strip()
    chunk["task_key"] = chunk["task_key"].replace("", pd.NA)

    # Clean important categorical columns.
    for column in ["project_key", "priority", "issue_type", "status_name"]:
        chunk[column] = chunk[column].astype("string").str.strip()
        chunk[column] = chunk[column].replace("", pd.NA).fillna("Unknown")

    # Keep unresolved issues clear instead of leaving an empty value.
    chunk["resolution_name"] = chunk["resolution_name"].astype("string").str.strip()
    chunk["resolution_name"] = (
        chunk["resolution_name"].replace("", pd.NA).fillna("Unresolved")
    )

    # Convert the subtask flag to 0 or 1.
    subtask_text = chunk["is_subtask"].astype("string").str.lower().str.strip()
    chunk["is_subtask"] = (
        subtask_text
        .map({"true": 1, "false": 0, "1": 1, "0": 0})
        .fillna(0)
        .astype("int8")
    )

    # Convert text dates to real datetime values.
    for column in ["created_date", "updated_date", "completed_date"]:
        chunk[column] = pd.to_datetime(chunk[column], errors="coerce")

    # Remove rows that cannot be used safely.
    chunk = chunk.dropna(subset=["task_key", "created_date"])
    chunk = chunk.drop_duplicates(subset=["task_key"], keep="first")

    # Remove duplicate task keys that appeared in earlier chunks.
    new_rows = ~chunk["task_key"].isin(seen_keys)
    rows_removed_as_duplicates += int((~new_rows).sum())
    chunk = chunk.loc[new_rows].copy()
    seen_keys.update(chunk["task_key"].tolist())

    # Create lifecycle features.
    chunk["resolution_time_days"] = (
        chunk["completed_date"] - chunk["created_date"]
    ).dt.total_seconds() / 86400

    chunk["update_span_days"] = (
        chunk["updated_date"] - chunk["created_date"]
    ).dt.total_seconds() / 86400

    # Negative durations are invalid.
    chunk.loc[chunk["resolution_time_days"] < 0, "resolution_time_days"] = np.nan
    chunk.loc[chunk["update_span_days"] < 0, "update_span_days"] = np.nan

    # Create simple derived features.
    chunk["is_resolved"] = chunk["completed_date"].notna().astype("int8")
    chunk["created_year"] = chunk["created_date"].dt.year
    chunk["created_month"] = chunk["created_date"].dt.month
    chunk["created_dayofweek"] = chunk["created_date"].dt.dayofweek

    # Save the cleaned issues in chunks.
    chunk.to_csv(
        CLEAN_ISSUES_PATH,
        mode="w" if first_write else "a",
        header=first_write,
        index=False,
        date_format="%Y-%m-%d %H:%M:%S",
    )

    first_write = False
    rows_written += len(chunk)

    if chunk_number % 5 == 0:
        print(f"Issue rows prepared: {rows_written:,}")

print("\nFinished issues cleaning.")
print("Rows written:", f"{rows_written:,}")
print("Duplicate keys removed:", f"{rows_removed_as_duplicates:,}")


# ------------------------------------------------------------
# 7. Build dependency features from issuelinks.csv
# ------------------------------------------------------------

links = pd.read_csv(
    LINKS_PATH,
    compression="zip",
    usecols=[
        "key",
        "type.name",
        "type.inward",
        "type.outward",
        "inwardIssue.key",
        "outwardIssue.key",
    ],
    low_memory=False,
)

links["task_key"] = links["key"].astype("string").str.strip()
links = links.dropna(subset=["task_key"])

# Combine link text so blocking relations can be detected.
relation_text = (
    links["type.name"].fillna("").astype(str) + " "
    + links["type.inward"].fillna("").astype(str) + " "
    + links["type.outward"].fillna("").astype(str)
).str.lower()

links["is_dependency"] = relation_text.str.contains(
    "block", regex=False, na=False
).astype("int8")

links["has_inward_link"] = links["inwardIssue.key"].notna().astype("int8")
links["has_outward_link"] = links["outwardIssue.key"].notna().astype("int8")

# Create one dependency-feature row per task.
link_features = (
    links.groupby("task_key")
    .agg(
        issue_link_count=("task_key", "size"),
        dependency_count=("is_dependency", "sum"),
        inward_link_count=("has_inward_link", "sum"),
        outward_link_count=("has_outward_link", "sum"),
    )
)

print("\nTasks with issue-link features:", f"{len(link_features):,}")
print(link_features.head())

# Free memory because the raw links table is not needed after aggregation.
del links


# ------------------------------------------------------------
# 8. Build historical features from changelog.csv
# ------------------------------------------------------------

changelog_features = None
rows_processed = 0

reader = pd.read_csv(
    CHANGELOG_PATH,
    compression="zip",
    usecols=["key", "field", "toString"],
    chunksize=CHUNK_SIZE,
    low_memory=False,
)

for chunk_number, chunk in enumerate(reader, start=1):
    rows_processed += len(chunk)

    chunk["task_key"] = chunk["key"].astype("string").str.strip()
    chunk = chunk.dropna(subset=["task_key"])

    field = chunk["field"].fillna("").astype(str).str.strip().str.lower()
    new_value = chunk["toString"].fillna("").astype(str).str.strip().str.lower()

    # Count important changes for each task.
    temp = pd.DataFrame({
        "task_key": chunk["task_key"],
        "total_change_count": 1,
        "status_change_count": (field == "status").astype("int8"),
        "assignee_change_count": (field == "assignee").astype("int8"),
        "priority_change_count": (field == "priority").astype("int8"),
        "issue_type_change_count": field.isin(
            ["issuetype", "issue type"]
        ).astype("int8"),
        "project_change_count": (field == "project").astype("int8"),
        "reopen_count": (
            (field == "status")
            & new_value.str.contains("reopen", regex=False, na=False)
        ).astype("int8"),
    })

    part = temp.groupby("task_key").sum(numeric_only=True)

    if changelog_features is None:
        changelog_features = part
    else:
        changelog_features = changelog_features.add(part, fill_value=0)

    if chunk_number % 10 == 0:
        print(f"Changelog rows processed: {rows_processed:,}")

if changelog_features is None:
    raise ValueError("No changelog rows were available after preprocessing.")

changelog_features = changelog_features.fillna(0).astype("int64")

print("\nTasks with changelog features:", f"{len(changelog_features):,}")
print(changelog_features.head())


# ------------------------------------------------------------
# 9. Merge issues, dependency features, and changelog features
# ------------------------------------------------------------

if ENRICHED_PATH.exists():
    ENRICHED_PATH.unlink()

count_columns = [
    "issue_link_count",
    "dependency_count",
    "inward_link_count",
    "outward_link_count",
    "total_change_count",
    "status_change_count",
    "assignee_change_count",
    "priority_change_count",
    "issue_type_change_count",
    "project_change_count",
    "reopen_count",
]

first_write = True
rows_written = 0

reader = pd.read_csv(
    CLEAN_ISSUES_PATH,
    chunksize=CHUNK_SIZE,
    parse_dates=["created_date", "updated_date", "completed_date"],
    low_memory=False,
)

for chunk_number, chunk in enumerate(reader, start=1):
    # Add dependency information.
    chunk = chunk.merge(
        link_features,
        how="left",
        left_on="task_key",
        right_index=True,
    )

    # Add issue history information.
    chunk = chunk.merge(
        changelog_features,
        how="left",
        left_on="task_key",
        right_index=True,
    )

    # Missing counts mean that no matching link or change was found.
    for column in count_columns:
        chunk[column] = chunk[column].fillna(0).astype("int64")

    chunk["has_dependencies"] = (
        chunk["dependency_count"] > 0
    ).astype("int8")

    chunk.to_csv(
        ENRICHED_PATH,
        mode="w" if first_write else "a",
        header=first_write,
        index=False,
        date_format="%Y-%m-%d %H:%M:%S",
    )

    first_write = False
    rows_written += len(chunk)

    if chunk_number % 5 == 0:
        print(f"Enriched rows written: {rows_written:,}")

print("\nMerge complete.")
print("Rows in enriched dataset:", f"{rows_written:,}")


# ------------------------------------------------------------
# 10. Define the supervised targets and safe baseline features
# ------------------------------------------------------------

# Regression target:
# Predict how many days a resolved issue took to complete.
REGRESSION_TARGET = "resolution_time_days"

# Classification target:
# This is a proxy risk label created from the Training-only 75th percentile.
CLASSIFICATION_TARGET = "long_resolution_risk"

# Isolation Forest does not use a supervised target.
BOTTLENECK_TARGET = None

MODEL_TARGETS = {
    "regression": REGRESSION_TARGET,
    "classification": CLASSIFICATION_TARGET,
    "bottleneck_isolation_forest": BOTTLENECK_TARGET,
}

# These features are available at issue creation time.
BASELINE_FEATURES = [
    "project_key",
    "priority",
    "issue_type",
    "is_subtask",
    "created_year",
    "created_month",
    "created_dayofweek",
]

print("\nModel targets:")
for model_name, target in MODEL_TARGETS.items():
    print(f"- {model_name}: {target}")

print("\nCreation-time baseline features:")
for feature in BASELINE_FEATURES:
    print("-", feature)


# ------------------------------------------------------------
# 11. Create chronological Train / Validation / Test cutoffs
# ------------------------------------------------------------

split_info = pd.read_csv(
    ENRICHED_PATH,
    usecols=[
        "created_date",
        "resolution_time_days",
        "priority_change_count",
        "issue_type_change_count",
        "project_change_count",
    ],
    parse_dates=["created_date"],
)

# Use resolved issues and avoid current/final values that changed later.
eligible_mask = (
    split_info["resolution_time_days"].notna()
    & (split_info["priority_change_count"].fillna(0) == 0)
    & (split_info["issue_type_change_count"].fillna(0) == 0)
    & (split_info["project_change_count"].fillna(0) == 0)
)

eligible_dates = (
    split_info.loc[eligible_mask]
    .sort_values("created_date")
    .reset_index(drop=True)
)

n_eligible = len(eligible_dates)
if n_eligible < 3:
    raise ValueError(
        "Not enough eligible rows to create Train, Validation, and Test splits."
    )

# 70% Train, 15% Validation, 15% Test.
train_end = max(1, int(n_eligible * 0.70))
validation_end = max(train_end + 1, int(n_eligible * 0.85))
validation_end = min(validation_end, n_eligible - 1)

train_cutoff = eligible_dates.loc[train_end - 1, "created_date"]
validation_cutoff = eligible_dates.loc[validation_end - 1, "created_date"]

# Create the classification threshold from Training only.
training_targets = eligible_dates.loc[
    eligible_dates["created_date"] <= train_cutoff,
    "resolution_time_days",
]

risk_threshold_days = float(training_targets.quantile(0.75))

print("\nEligible supervised rows:", f"{n_eligible:,}")
print("Training cutoff:", train_cutoff)
print("Validation cutoff:", validation_cutoff)
print(
    "Training-only 75th percentile:",
    round(risk_threshold_days, 2),
    "days",
)

# We no longer need the full split helper table.
del split_info, eligible_dates, training_targets


# ------------------------------------------------------------
# 12. Learn categorical values from Training only
# ------------------------------------------------------------

CATEGORICAL_FEATURES = [
    "project_key",
    "priority",
    "issue_type",
]

NUMERIC_FEATURES = [
    "is_subtask",
    "created_year",
    "created_month",
    "created_dayofweek",
]

# Start every categorical feature with an Unknown category.
category_values = {
    column: {"Unknown"}
    for column in CATEGORICAL_FEATURES
}

reader = pd.read_csv(
    ENRICHED_PATH,
    usecols=[
        "created_date",
        "resolution_time_days",
        "priority_change_count",
        "issue_type_change_count",
        "project_change_count",
        *CATEGORICAL_FEATURES,
    ],
    chunksize=CHUNK_SIZE,
    parse_dates=["created_date"],
    low_memory=False,
)

for chunk in reader:
    eligible = (
        chunk["resolution_time_days"].notna()
        & (chunk["priority_change_count"].fillna(0) == 0)
        & (chunk["issue_type_change_count"].fillna(0) == 0)
        & (chunk["project_change_count"].fillna(0) == 0)
        & (chunk["created_date"] <= train_cutoff)
    )

    train_chunk = chunk.loc[eligible]

    for column in CATEGORICAL_FEATURES:
        values = (
            train_chunk[column]
            .fillna("Unknown")
            .astype(str)
            .unique()
        )
        category_values[column].update(values)

# Sort categories to keep the same output order every time.
for column in CATEGORICAL_FEATURES:
    category_values[column] = sorted(category_values[column])

print("\nTraining categories:")
for column in CATEGORICAL_FEATURES:
    print(f"- {column}: {len(category_values[column])}")


# ------------------------------------------------------------
# 13. Build the final numerical feature list
# ------------------------------------------------------------

DUMMY_COLUMNS = []

for column in CATEGORICAL_FEATURES:
    for value in category_values[column]:
        DUMMY_COLUMNS.append(f"{column}_{value}")

ML_FEATURE_COLUMNS = NUMERIC_FEATURES + DUMMY_COLUMNS

# The Regression and Classification models use the same X features.
REGRESSION_FEATURES = ML_FEATURE_COLUMNS
CLASSIFICATION_FEATURES = ML_FEATURE_COLUMNS

print("\nNumeric base features:", len(NUMERIC_FEATURES))
print("Dummy features:", len(DUMMY_COLUMNS))
print("Total supervised model features:", len(ML_FEATURE_COLUMNS))


# ------------------------------------------------------------
# 14. Export the final dataset and supervised ML splits
# ------------------------------------------------------------

for path in [FINAL_DATASET_PATH, TRAIN_PATH, VALIDATION_PATH, TEST_PATH]:
    if path.exists():
        path.unlink()

first_final = True
first_split = {
    "train": True,
    "validation": True,
    "test": True,
}

counts = {
    "final": 0,
    "train": 0,
    "validation": 0,
    "test": 0,
}

reader = pd.read_csv(
    ENRICHED_PATH,
    chunksize=CHUNK_SIZE,
    parse_dates=["created_date"],
    low_memory=False,
)

for chunk_number, chunk in enumerate(reader, start=1):
    # Create the Classification proxy target.
    # The threshold came from Training only, so Validation and Test do not
    # influence the target threshold.
    chunk["long_resolution_risk"] = pd.Series(
        pd.NA,
        index=chunk.index,
        dtype="Int64",
    )

    resolved = chunk["resolution_time_days"].notna()

    chunk.loc[resolved, "long_resolution_risk"] = (
        chunk.loc[resolved, "resolution_time_days"] >= risk_threshold_days
    ).astype("int8")

    # Save the readable full analytical dataset.
    chunk.to_csv(
        FINAL_DATASET_PATH,
        mode="w" if first_final else "a",
        header=first_final,
        index=False,
        date_format="%Y-%m-%d %H:%M:%S",
    )

    first_final = False
    counts["final"] += len(chunk)

    # Keep rows valid for the creation-time supervised baseline.
    eligible = (
        chunk["resolution_time_days"].notna()
        & (chunk["priority_change_count"].fillna(0) == 0)
        & (chunk["issue_type_change_count"].fillna(0) == 0)
        & (chunk["project_change_count"].fillna(0) == 0)
    )

    model_data = chunk.loc[
        eligible,
        [
            "task_key",
            "created_date",
            *CATEGORICAL_FEATURES,
            *NUMERIC_FEATURES,
            REGRESSION_TARGET,
            CLASSIFICATION_TARGET,
        ],
    ].copy()

    # Split by time.
    train_part = model_data.loc[
        model_data["created_date"] <= train_cutoff
    ].copy()

    validation_part = model_data.loc[
        (model_data["created_date"] > train_cutoff)
        & (model_data["created_date"] <= validation_cutoff)
    ].copy()

    test_part = model_data.loc[
        model_data["created_date"] > validation_cutoff
    ].copy()

    split_parts = [
        ("train", train_part, TRAIN_PATH),
        ("validation", validation_part, VALIDATION_PATH),
        ("test", test_part, TEST_PATH),
    ]

    for split_name, part, path in split_parts:
        if part.empty:
            continue

        # Use only category values that were learned from Training.
        for column in CATEGORICAL_FEATURES:
            part[column] = part[column].fillna("Unknown").astype(str)

            allowed_values = category_values[column]

            part.loc[
                ~part[column].isin(allowed_values),
                column,
            ] = "Unknown"

        # Convert categorical columns to 0/1 dummy columns.
        part = pd.get_dummies(
            part,
            columns=CATEGORICAL_FEATURES,
            dtype="int8",
        )

        # Keep exactly the same feature columns and order in every split.
        final_columns = [
            "task_key",
            "created_date",
            *ML_FEATURE_COLUMNS,
            REGRESSION_TARGET,
            CLASSIFICATION_TARGET,
        ]

        # Reindex also creates any missing dummy column with value 0.
        part = part.reindex(
            columns=final_columns,
            fill_value=0,
        )

        part.to_csv(
            path,
            mode="w" if first_split[split_name] else "a",
            header=first_split[split_name],
            index=False,
            date_format="%Y-%m-%d %H:%M:%S",
        )

        first_split[split_name] = False
        counts[split_name] += len(part)

    if chunk_number % 5 == 0:
        print(
            f"final={counts['final']:,} | "
            f"train={counts['train']:,} | "
            f"validation={counts['validation']:,} | "
            f"test={counts['test']:,}"
        )

print("\nSupervised export complete.")
print(counts)


# ------------------------------------------------------------
# 15. Prepare the Bottleneck Detection dataset
# ------------------------------------------------------------

# IMPORTANT:
# Isolation Forest is unsupervised, so this dataset has NO target column.
# The future model will create anomaly_score and potential_bottleneck outputs.
#
# This first version is a historical anomaly baseline because
# resolution_time_days is only known for resolved issues.
# Do not use anomaly_score or potential_bottleneck as input features.

BOTTLENECK_FEATURES = [
    "resolution_time_days",
    "update_span_days",
    "issue_link_count",
    "dependency_count",
    "inward_link_count",
    "outward_link_count",
    "total_change_count",
    "status_change_count",
    "assignee_change_count",
    "reopen_count",
]

BOTTLENECK_AUDIT_COLUMNS = [
    "task_key",
    "project_key",
    "created_date",
]

if BOTTLENECK_DATASET_PATH.exists():
    BOTTLENECK_DATASET_PATH.unlink()

first_write = True
bottleneck_rows = 0

reader = pd.read_csv(
    FINAL_DATASET_PATH,
    usecols=BOTTLENECK_AUDIT_COLUMNS + BOTTLENECK_FEATURES,
    chunksize=CHUNK_SIZE,
    parse_dates=["created_date"],
    low_memory=False,
)

for chunk in reader:
    # Keep resolved tasks because resolution_time_days is needed here.
    chunk = chunk.loc[
        chunk["resolution_time_days"].notna()
    ].copy()

    # Convert all Isolation Forest input features to numeric values.
    for column in BOTTLENECK_FEATURES:
        chunk[column] = pd.to_numeric(chunk[column], errors="coerce")

    # Keep only rows with complete bottleneck input features.
    # No target is created here.
    chunk = chunk.dropna(subset=BOTTLENECK_FEATURES)

    if chunk.empty:
        continue

    chunk.to_csv(
        BOTTLENECK_DATASET_PATH,
        mode="w" if first_write else "a",
        header=first_write,
        index=False,
        date_format="%Y-%m-%d %H:%M:%S",
    )

    first_write = False
    bottleneck_rows += len(chunk)

if first_write:
    raise ValueError("No rows were available for the bottleneck dataset.")

print("\nBottleneck dataset rows:", f"{bottleneck_rows:,}")
print("Saved:", BOTTLENECK_DATASET_PATH)


# ------------------------------------------------------------
# 16. Check final output files
# ------------------------------------------------------------

output_files = [
    FINAL_DATASET_PATH,
    TRAIN_PATH,
    VALIDATION_PATH,
    TEST_PATH,
    BOTTLENECK_DATASET_PATH,
    MAPPING_PATH,
]

print("\nOutput files:")
for path in output_files:
    size_mb = round(path.stat().st_size / (1024 ** 2), 2) if path.exists() else None
    print(f"- {path.name}: exists={path.exists()}, size_mb={size_mb}")


# ------------------------------------------------------------
# 17. Run lightweight quality checks
# ------------------------------------------------------------

def summarize_split(path, split_name):
    """Check one supervised split without loading the full file into memory."""

    total_rows = 0
    missing_regression_target = 0
    missing_classification_target = 0
    min_date = None
    max_date = None

    reader = pd.read_csv(
        path,
        usecols=[
            "created_date",
            REGRESSION_TARGET,
            CLASSIFICATION_TARGET,
        ],
        chunksize=CHUNK_SIZE,
        parse_dates=["created_date"],
    )

    for chunk in reader:
        total_rows += len(chunk)
        missing_regression_target += int(chunk[REGRESSION_TARGET].isna().sum())
        missing_classification_target += int(
            chunk[CLASSIFICATION_TARGET].isna().sum()
        )

        chunk_min = chunk["created_date"].min()
        chunk_max = chunk["created_date"].max()

        if min_date is None or chunk_min < min_date:
            min_date = chunk_min
        if max_date is None or chunk_max > max_date:
            max_date = chunk_max

    return {
        "split": split_name,
        "rows": total_rows,
        "min_date": min_date,
        "max_date": max_date,
        "missing_regression_target": missing_regression_target,
        "missing_classification_target": missing_classification_target,
    }


quality_summary = pd.DataFrame([
    summarize_split(TRAIN_PATH, "train"),
    summarize_split(VALIDATION_PATH, "validation"),
    summarize_split(TEST_PATH, "test"),
])

print("\nSplit quality summary:")
print(quality_summary.to_string(index=False))

# Check the split dates.
assert quality_summary.loc[
    quality_summary["split"] == "train", "max_date"
].iloc[0] <= train_cutoff

assert quality_summary.loc[
    quality_summary["split"] == "validation", "min_date"
].iloc[0] > train_cutoff

assert quality_summary.loc[
    quality_summary["split"] == "validation", "max_date"
].iloc[0] <= validation_cutoff

assert quality_summary.loc[
    quality_summary["split"] == "test", "min_date"
].iloc[0] > validation_cutoff

# Both supervised targets must be complete.
assert quality_summary["missing_regression_target"].sum() == 0
assert quality_summary["missing_classification_target"].sum() == 0

# Check that all supervised model features are numeric.
train_sample = pd.read_csv(TRAIN_PATH, nrows=1000)
non_numeric_features = (
    train_sample[ML_FEATURE_COLUMNS]
    .select_dtypes(exclude="number")
    .columns
    .tolist()
)
assert len(non_numeric_features) == 0

# Check that the Bottleneck dataset has no supervised output columns.
bottleneck_sample = pd.read_csv(BOTTLENECK_DATASET_PATH, nrows=1000)

assert "anomaly_score" not in bottleneck_sample.columns
assert "potential_bottleneck" not in bottleneck_sample.columns
assert CLASSIFICATION_TARGET not in bottleneck_sample.columns

# The Bottleneck model input features must be numeric.
non_numeric_bottleneck_features = (
    bottleneck_sample[BOTTLENECK_FEATURES]
    .select_dtypes(exclude="number")
    .columns
    .tolist()
)
assert len(non_numeric_bottleneck_features) == 0

print("\nQuality checks: PASS")


# ------------------------------------------------------------
# 18. Save preprocessing metadata for the next ML person
# ------------------------------------------------------------

metadata = {
    "task": "Prepare and Preprocess the AI/ML Dataset",
    "dataset": "Apache JIRA Issues",
    "models": {
        "regression": {
            "target": REGRESSION_TARGET,
            "features": REGRESSION_FEATURES,
            "data_files": [
                TRAIN_PATH.name,
                VALIDATION_PATH.name,
                TEST_PATH.name,
            ],
        },
        "classification": {
            "target": CLASSIFICATION_TARGET,
            "target_type": "proxy",
            "target_definition": (
                "1 when resolution_time_days is greater than or equal to the "
                "Training-only 75th percentile, otherwise 0"
            ),
            "features": CLASSIFICATION_FEATURES,
            "data_files": [
                TRAIN_PATH.name,
                VALIDATION_PATH.name,
                TEST_PATH.name,
            ],
        },
        "bottleneck_isolation_forest": {
            "target": None,
            "features": BOTTLENECK_FEATURES,
            "data_file": BOTTLENECK_DATASET_PATH.name,
            "future_outputs": [
                "anomaly_score",
                "potential_bottleneck",
            ],
            "note": (
                "This is an unsupervised historical anomaly baseline. "
                "anomaly_score and potential_bottleneck must be created "
                "by the Isolation Forest model, not used as inputs."
            ),
        },
    },
    "risk_threshold_days": round(risk_threshold_days, 4),
    "train_cutoff": str(train_cutoff),
    "validation_cutoff": str(validation_cutoff),
    "split_ratio": {
        "train": 0.70,
        "validation": 0.15,
        "test": 0.15,
    },
    "categorical_features": CATEGORICAL_FEATURES,
    "numeric_features": NUMERIC_FEATURES,
    "training_categories": category_values,
    "ml_feature_columns": ML_FEATURE_COLUMNS,
    "bottleneck_features": BOTTLENECK_FEATURES,
    "split_counts": counts,
    "bottleneck_rows": bottleneck_rows,
    "comments_used_in_current_model": False,
}

with open(METADATA_PATH, "w", encoding="utf-8") as file:
    json.dump(metadata, file, indent=2)

print("\nSaved metadata:", METADATA_PATH)


# ------------------------------------------------------------
# 19. Remove temporary files
# ------------------------------------------------------------

for path in [CLEAN_ISSUES_PATH, ENRICHED_PATH]:
    if path.exists():
        path.unlink()
        print("Removed temporary file:", path.name)


# ------------------------------------------------------------
# 20. Final guide for model training
# ------------------------------------------------------------

print("\n" + "=" * 80)
print("DATA PREPARATION COMPLETE")
print("=" * 80)

print("\nRegression model")
print("Target:", REGRESSION_TARGET)
print("Features: ML_FEATURE_COLUMNS")
print("Files: train.csv, validation.csv, test.csv")

print("\nClassification model")
print("Target:", CLASSIFICATION_TARGET)
print("Features: ML_FEATURE_COLUMNS")
print("Files: train.csv, validation.csv, test.csv")

print("\nIsolation Forest - Bottleneck Detection")
print("Target: None")
print("Features: BOTTLENECK_FEATURES")
print("File: bottleneck_dataset.csv")
print("Future outputs: anomaly_score, potential_bottleneck")

print("\nDo not use target columns as input features.")
print("Do not create anomaly_score or potential_bottleneck before Isolation Forest.")
