import pandas as pd


def clean_projects(projects: pd.DataFrame) -> pd.DataFrame:
    """
    Clean the main projects dataset.
    """

    df = projects.copy()

    # Convert project creation timestamp to datetime
    df["created_at"] = pd.to_datetime(
        df["created_at"],
        errors="coerce",
        utc=True,
    )

    # Remove rows without a valid project ID
    df = df.dropna(subset=["id"])

    # Remove duplicate project records
    df = df.drop_duplicates(subset=["id"])

    return df


def clean_projects_computed(projects_computed: pd.DataFrame) -> pd.DataFrame:
    """
    Clean computed project duration data.
    """

    df = projects_computed.copy()

    # Convert project creation timestamp to datetime
    df["created_at"] = pd.to_datetime(
        df["created_at"],
        errors="coerce",
        utc=True,
    )

    # Convert duration strings into numeric hours
    df["planned_hours"] = df["planned_duration"].apply(
        parse_duration_to_hours
    )

    df["elapsed_hours"] = df["elapsed_duration"].apply(
        parse_duration_to_hours
    )

    # Remove rows without a valid project ID
    df = df.dropna(subset=["id"])

    # Remove duplicate project records
    df = df.drop_duplicates(subset=["id"])

    # Replace negative durations with zero
    df.loc[df["planned_hours"] < 0, "planned_hours"] = 0
    df.loc[df["elapsed_hours"] < 0, "elapsed_hours"] = 0

    # Remove extremely unrealistic duration values
    df.loc[df["planned_hours"] > 10000, "planned_hours"] = pd.NA
    df.loc[df["elapsed_hours"] > 10000, "elapsed_hours"] = pd.NA

    return df


def clean_tasks(tasks: pd.DataFrame) -> pd.DataFrame:
    """
    Clean the main tasks dataset.
    """

    df = tasks.copy()

    # Convert task creation timestamp to datetime
    df["created_at"] = pd.to_datetime(
        df["created_at"],
        errors="coerce",
        utc=True,
    )

    # Remove rows without a valid task ID
    df = df.dropna(subset=["id"])

    # Remove duplicate task records
    df = df.drop_duplicates(subset=["id"])

    return df


def clean_tasks_computed(tasks_computed: pd.DataFrame) -> pd.DataFrame:
    """
    Clean computed task duration data.
    """

    df = tasks_computed.copy()

    # Convert task creation timestamp to datetime
    df["created_at"] = pd.to_datetime(
        df["created_at"],
        errors="coerce",
        utc=True,
    )

    # Convert duration strings into numeric hours
    df["planned_hours"] = df["planned_duration"].apply(
        parse_duration_to_hours
    )

    df["elapsed_hours"] = df["elapsed_duration"].apply(
        parse_duration_to_hours
    )

    # Remove rows without a valid task ID
    df = df.dropna(subset=["id"])

    # Remove duplicate task records
    df = df.drop_duplicates(subset=["id"])

    # Replace negative durations with zero
    df.loc[df["planned_hours"] < 0, "planned_hours"] = 0
    df.loc[df["elapsed_hours"] < 0, "elapsed_hours"] = 0

    # Remove extremely unrealistic duration values
    df.loc[df["planned_hours"] > 10000, "planned_hours"] = pd.NA
    df.loc[df["elapsed_hours"] > 10000, "elapsed_hours"] = pd.NA

    return df


def clean_declarations(declarations: pd.DataFrame) -> pd.DataFrame:
    """
    Clean time-tracking declarations.
    """

    df = declarations.copy()

    # Convert timestamps and dates into datetime values
    df["created_at"] = pd.to_datetime(
        df["created_at"],
        errors="coerce",
        utc=True,
    )

    df["date"] = pd.to_datetime(
        df["date"],
        errors="coerce",
        utc=True,
    )

    # Convert nanoseconds into hours
    df["logged_hours"] = pd.to_numeric(
        df["duration"],
        errors="coerce",
    ) / 3_600_000_000_000

    # Remove declarations without a task ID
    df = df.dropna(subset=["task_id"])

    # Replace negative logged durations with zero
    df.loc[df["logged_hours"] < 0, "logged_hours"] = 0

    # Remove extremely unrealistic individual time entries
    df.loc[df["logged_hours"] > 24, "logged_hours"] = pd.NA

    return df


def parse_duration_to_hours(value) -> float:
    """
    Convert Gryzzly duration strings into hours.

    Examples:
        3h30m0s -> 3.5
        6h0m0s  -> 6.0
        0s      -> 0.0
    """

    # Handle missing values
    if pd.isna(value):
        return 0.0

    # Convert the value to string for safe parsing
    value = str(value).strip()

    # Return zero for empty values
    if not value:
        return 0.0

    # Initialize duration components
    days = 0.0
    hours = 0.0
    minutes = 0.0
    seconds = 0.0

    # Parse days
    if "d" in value:
        part, value = value.split("d", 1)
        days = float(part or 0)

    # Parse hours
    if "h" in value:
        part, value = value.split("h", 1)
        hours = float(part or 0)

    # Parse minutes
    if "m" in value:
        part, value = value.split("m", 1)
        minutes = float(part or 0)

    # Parse seconds
    if "s" in value:
        part = value.split("s", 1)[0]
        seconds = float(part or 0)

    # Convert the complete duration into hours
    return (
        days * 24
        + hours
        + minutes / 60
        + seconds / 3600
    )