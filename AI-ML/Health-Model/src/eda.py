import pandas as pd


def analyze_projects(
    projects: pd.DataFrame,
    projects_computed: pd.DataFrame,
) -> None:
    """
    Analyze project-level data and duration statistics.
    """

    print("\n=== PROJECT EDA ===")

    # Display the number of unique projects in each dataset
    print(f"Projects dataset: {projects['id'].nunique():,}")

    print(
        f"Projects computed dataset: "
        f"{projects_computed['id'].nunique():,}"
    )

    # Calculate the overlap between the two project datasets
    project_overlap = set(projects["id"]).intersection(
        set(projects_computed["id"])
    )

    print(f"Project ID overlap: {len(project_overlap):,}")

    # Calculate projects with valid planned and elapsed durations
    valid_planned = (
        projects_computed["planned_hours"] > 0
    ).sum()

    valid_elapsed = (
        projects_computed["elapsed_hours"] > 0
    ).sum()

    print(
        f"Projects with planned duration > 0: "
        f"{valid_planned:,}"
    )

    print(
        f"Projects with elapsed duration > 0: "
        f"{valid_elapsed:,}"
    )

    # Display descriptive statistics for project durations
    print("\nProject duration statistics:")

    print(
        projects_computed[
            ["planned_hours", "elapsed_hours"]
        ].describe()
    )


def analyze_tasks(
    tasks: pd.DataFrame,
    tasks_computed: pd.DataFrame,
) -> None:
    """
    Analyze task-level data.
    """

    print("\n=== TASK EDA ===")

    # Display the number of unique tasks in each dataset
    print(f"Tasks dataset: {tasks['id'].nunique():,}")

    print(
        f"Tasks computed dataset: "
        f"{tasks_computed['id'].nunique():,}"
    )

    # Calculate the overlap between task datasets
    task_overlap = set(tasks["id"]).intersection(
        set(tasks_computed["id"])
    )

    print(f"Task ID overlap: {len(task_overlap):,}")

    # Count container and non-container tasks
    print("\nTask type distribution:")

    print(
        tasks["is_container"]
        .value_counts(dropna=False)
    )

    # Display task duration statistics
    print("\nTask duration statistics:")

    print(
        tasks_computed[
            ["planned_hours", "elapsed_hours"]
        ].describe()
    )


def analyze_declarations(
    declarations: pd.DataFrame,
) -> None:
    """
    Analyze time-tracking declarations.
    """

    print("\n=== DECLARATION EDA ===")

    # Count unique tasks that have time declarations
    print(
        f"Unique tasks with declarations: "
        f"{declarations['task_id'].nunique():,}"
    )

    # Count unique users who logged time
    print(
        f"Unique active users: "
        f"{declarations['user_id'].nunique():,}"
    )

    # Count unique active days
    print(
        f"Active dates: "
        f"{declarations['date'].dt.date.nunique():,}"
    )

    # Display logged-hours statistics
    print("\nLogged hours statistics:")

    print(
        declarations["logged_hours"].describe()
    )

    # Display declaration source distribution
    print("\nDeclaration sources:")

    print(
        declarations["source"]
        .value_counts(dropna=False)
        .head(10)
    )


def analyze_project_outcomes(
    projects_computed: pd.DataFrame,
) -> None:
    """
    Analyze project outcomes based on budget consumption.

    The Gryzzly paper defines a project as failed when
    consumed budget exceeds the initial planned allocation.
    """

    print("\n=== PROJECT OUTCOME ANALYSIS ===")

    # Keep only projects with a valid planned budget
    budgeted_projects = projects_computed[
        projects_computed["planned_hours"].notna()
        & (projects_computed["planned_hours"] > 0)
    ].copy()

    print(
        f"Projects with a valid planned budget: "
        f"{len(budgeted_projects):,}"
    )

    # Calculate the budget consumption ratio
    budgeted_projects["budget_ratio"] = (
        budgeted_projects["elapsed_hours"]
        / budgeted_projects["planned_hours"]
    )

    # Identify projects that exceeded their planned budget
    budgeted_projects["failed_budget"] = (
        budgeted_projects["budget_ratio"] > 1
    )

    # Count projects above and below the budget
    outcome_counts = (
        budgeted_projects["failed_budget"]
        .value_counts()
    )

    print("\nBudget outcome distribution:")

    print(outcome_counts)

    # Calculate percentages
    outcome_percentages = (
        budgeted_projects["failed_budget"]
        .value_counts(normalize=True)
        .mul(100)
    )

    print("\nBudget outcome percentages:")

    print(outcome_percentages.round(2))

    # Display budget consumption statistics
    print("\nBudget ratio statistics:")

    print(
        budgeted_projects["budget_ratio"].describe()
    )