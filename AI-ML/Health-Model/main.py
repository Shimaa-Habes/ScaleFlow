from src.data_loading import (
    load_projects,
    load_projects_computed,
    load_tasks,
    load_tasks_computed,
    load_declarations,
)

from src.cleaning import (
    clean_projects,
    clean_projects_computed,
    clean_tasks,
    clean_tasks_computed,
    clean_declarations,
)

from src.eda import (
    analyze_projects,
    analyze_tasks,
    analyze_declarations,
    analyze_project_outcomes,
)

from src.features import build_project_features
from src.preprocessing import prepare_dataset
from src.model import train_models
from src.evaluation import evaluate_model
from src.save_artifacts import (
    save_model,
    save_artifact,
)


def main():
    print("=== Loading Gryzzly datasets ===")

    # Load all raw datasets.
    projects = load_projects()
    projects_computed = load_projects_computed()
    tasks = load_tasks()
    tasks_computed = load_tasks_computed()
    declarations = load_declarations()

    print(f"Projects: {projects.shape}")
    print(f"Projects computed: {projects_computed.shape}")
    print(f"Tasks: {tasks.shape}")
    print(f"Tasks computed: {tasks_computed.shape}")
    print(f"Declarations: {declarations.shape}")

    print("\n=== Cleaning datasets ===")

    # Clean project datasets.
    projects = clean_projects(projects)
    projects_computed = clean_projects_computed(
        projects_computed
    )

    # Clean task datasets.
    tasks = clean_tasks(tasks)
    tasks_computed = clean_tasks_computed(
        tasks_computed
    )

    # Clean time-tracking declarations.
    declarations = clean_declarations(
        declarations
    )

    print(f"Clean projects: {projects.shape}")
    print(
        f"Clean projects computed: "
        f"{projects_computed.shape}"
    )
    print(f"Clean tasks: {tasks.shape}")
    print(
        f"Clean tasks computed: "
        f"{tasks_computed.shape}"
    )
    print(
        f"Clean declarations: "
        f"{declarations.shape}"
    )

    print("\n=== Exploratory Data Analysis ===")

    # Analyze project-level information.
    analyze_projects(
        projects,
        projects_computed,
    )

    # Analyze task-level information.
    analyze_tasks(
        tasks,
        tasks_computed,
    )

    # Analyze time-tracking information.
    analyze_declarations(
        declarations,
    )

    # Analyze project outcomes.
    analyze_project_outcomes(
        projects_computed,
    )

    print("\n=== Feature Engineering ===")

    # Build project-level features.
    project_features = build_project_features(
        projects,
        projects_computed,
        tasks,
        tasks_computed,
        declarations,
    )

    print(
        f"Project feature dataset: "
        f"{project_features.shape}"
    )

    print("\n=== Preparing ML Dataset ===")

    # Prepare the training and testing datasets.
    (
        X_train,
        X_test,
        y_train,
        y_test,
        imputer,
        scaler,
        feature_names,
    ) = prepare_dataset(
        project_features
    )

    print("\n=== Model Training ===")

    # Train the baseline health models.
    models = train_models(
        X_train,
        y_train,
    )

    print("\n=== Model Evaluation ===")

    # Evaluate Logistic Regression.
    logistic_metrics = evaluate_model(
        models["logistic_regression"],
        X_test,
        y_test,
        "Logistic Regression",
    )

    # Evaluate Random Forest.
    random_forest_metrics = evaluate_model(
        models["random_forest"],
        X_test,
        y_test,
        "Random Forest",
    )

    print("\n=== Saving Artifacts ===")

    # Save the trained models.
    save_model(
        models["logistic_regression"],
        "health_logistic_regression.joblib",
    )

    save_model(
        models["random_forest"],
        "health_random_forest.joblib",
    )

    # Save preprocessing artifacts.
    save_artifact(
        imputer,
        "health_imputer.joblib",
    )

    save_artifact(
        scaler,
        "health_scaler.joblib",
    )

    # Save the exact feature order used during training.
    save_artifact(
        feature_names,
        "health_feature_names.joblib",
    )

    print("\n=== HEALTH MODEL COMPLETE ===")

    print(
        f"Logistic Regression ROC-AUC: "
        f"{logistic_metrics['roc_auc']:.4f}"
    )

    print(
        f"Random Forest ROC-AUC: "
        f"{random_forest_metrics['roc_auc']:.4f}"
    )


if __name__ == "__main__":
    main()