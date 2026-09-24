from pathlib import Path
import pandas as pd


DATA_DIR = Path(__file__).resolve().parents[1] / "data"


def load_csv(filename: str) -> pd.DataFrame:
    path = DATA_DIR / filename

    if not path.exists():
        raise FileNotFoundError(f"Dataset not found: {path}")

    return pd.read_csv(path)


def load_projects() -> pd.DataFrame:
    return load_csv("projects.csv")


def load_projects_computed() -> pd.DataFrame:
    return load_csv("projects_computed.csv")


def load_tasks() -> pd.DataFrame:
    return load_csv("tasks.csv")


def load_tasks_computed() -> pd.DataFrame:
    return load_csv("tasks_computed.csv")


def load_declarations() -> pd.DataFrame:
    return load_csv("declarations.csv")