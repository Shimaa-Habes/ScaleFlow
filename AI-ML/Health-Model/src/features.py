import pandas as pd


def build_project_features(
    projects: pd.DataFrame,
    projects_computed: pd.DataFrame,
    tasks: pd.DataFrame,
    tasks_computed: pd.DataFrame,
    declarations: pd.DataFrame,
) -> pd.DataFrame:
    """
    Build one feature row for each project.

    The features combine project, task, and time-tracking information.
    """

    print("\n=== BUILDING PROJECT FEATURES ===")

    # ---------------------------------------------------------
    # 1. Start with projects that have computed duration data
    # ---------------------------------------------------------

    project_data = projects_computed[
        [
            "id",
            "planned_hours",
            "elapsed_hours",
            "created_at",
        ]
    ].copy()

    # Rename the project identifier for clarity
    project_data = project_data.rename(
        columns={"id": "project_id"}
    )

    # ---------------------------------------------------------
    # 2. Project duration features
    # ---------------------------------------------------------

    # Calculate the difference between actual and planned duration
    project_data["duration_variance_hours"] = (
        project_data["elapsed_hours"]
        - project_data["planned_hours"]
    )

    # Calculate how much of the planned duration was consumed
    project_data["duration_ratio"] = (
        project_data["elapsed_hours"]
        / project_data["planned_hours"].replace(0, pd.NA)
    )

    # Replace invalid infinite values
    project_data["duration_ratio"] = (
        project_data["duration_ratio"]
        .replace([float("inf"), float("-inf")], pd.NA)
    )

    # ---------------------------------------------------------
    # 3. Task-level aggregation
    # ---------------------------------------------------------

    task_data = tasks_computed[
        [
            "id",
            "project_id",
            "is_container",
            "planned_hours",
            "elapsed_hours",
        ]
    ].copy()

    # Aggregate task statistics per project
    task_features = (
        task_data
        .groupby("project_id")
        .agg(
            task_count=("id", "count"),
            task_planned_hours=("planned_hours", "sum"),
            task_elapsed_hours=("elapsed_hours", "sum"),
        )
        .reset_index()
    )

    # Count container tasks separately
    container_features = (
        task_data
        .assign(
            container_flag=(
                task_data["is_container"] == "t"
            ).astype("int8")
        )
        .groupby("project_id")
        .agg(
            container_task_count=("container_flag", "sum")
        )
        .reset_index()
    )

    # Merge task-level features into project data
    project_data = project_data.merge(
        task_features,
        on="project_id",
        how="left",
    )

    project_data = project_data.merge(
        container_features,
        on="project_id",
        how="left",
    )

    # ---------------------------------------------------------
    # 4. Declaration-level aggregation
    # ---------------------------------------------------------

    # Keep only the columns required to connect declarations
    task_project_map = tasks[
        [
            "id",
            "project_id",
        ]
    ].rename(
        columns={"id": "task_id"}
    )

    # Keep only the required declaration columns
    declaration_data = declarations[
        [
            "task_id",
            "user_id",
            "date",
            "logged_hours",
        ]
    ].copy()

    # Map each declaration to its project
    declaration_data = declaration_data.merge(
        task_project_map,
        on="task_id",
        how="inner",
    )

    print(
        f"Mapped declarations to projects: "
        f"{len(declaration_data):,}"
    )

    # Aggregate time-tracking information per project
    declaration_features = (
        declaration_data
        .groupby("project_id")
        .agg(
            declaration_count=("task_id", "count"),
            total_logged_hours=("logged_hours", "sum"),
            active_users=("user_id", "nunique"),
            active_days=("date", "nunique"),
        )
        .reset_index()
    )

    # Merge declaration features into project data
    project_data = project_data.merge(
        declaration_features,
        on="project_id",
        how="left",
    )

    # ---------------------------------------------------------
    # 5. Fill missing aggregation values
    # ---------------------------------------------------------

    count_columns = [
        "task_count",
        "container_task_count",
        "declaration_count",
        "active_users",
        "active_days",
    ]

    for column in count_columns:
        project_data[column] = (
            project_data[column]
            .fillna(0)
        )

    duration_columns = [
        "task_planned_hours",
        "task_elapsed_hours",
        "total_logged_hours",
    ]

    for column in duration_columns:
        project_data[column] = (
            project_data[column]
            .fillna(0)
        )

    # ---------------------------------------------------------
    # 6. Workload features
    # ---------------------------------------------------------

    # Average logged hours per active user
    project_data["avg_logged_hours_per_user"] = (
        project_data["total_logged_hours"]
        / project_data["active_users"].replace(0, pd.NA)
    )

    # Average logged hours per active day
    project_data["avg_logged_hours_per_day"] = (
        project_data["total_logged_hours"]
        / project_data["active_days"].replace(0, pd.NA)
    )

    # Average logged hours per task
    project_data["avg_logged_hours_per_task"] = (
        project_data["total_logged_hours"]
        / project_data["task_count"].replace(0, pd.NA)
    )

    # ---------------------------------------------------------
    # 7. Task duration features
    # ---------------------------------------------------------

    # Difference between task planned and actual hours
    project_data["task_duration_variance_hours"] = (
        project_data["task_elapsed_hours"]
        - project_data["task_planned_hours"]
    )

    # Ratio between actual and planned task hours
    project_data["task_duration_ratio"] = (
        project_data["task_elapsed_hours"]
        / project_data["task_planned_hours"].replace(0, pd.NA)
    )

    project_data["task_duration_ratio"] = (
        project_data["task_duration_ratio"]
        .replace([float("inf"), float("-inf")], pd.NA)
    )

    # ---------------------------------------------------------
    # 8. Final cleanup
    # ---------------------------------------------------------

    # Replace infinite values with missing values
    project_data = project_data.replace(
        [float("inf"), float("-inf")],
        pd.NA,
    )

    print(
        f"Generated project feature rows: "
        f"{len(project_data):,}"
    )

    print(
        f"Generated feature columns: "
        f"{len(project_data.columns):,}"
    )

    print("\nFeature columns:")
    print(project_data.columns.tolist())

    return project_data