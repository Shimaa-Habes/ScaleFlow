from pathlib import Path
import pandas as pd


def load_risk_dataset() -> pd.DataFrame:
    project_root = Path(__file__).resolve().parents[1]
    data_path = project_root / "data" / "project_risk_raw_dataset.csv"

    if not data_path.exists():
        raise FileNotFoundError(f"Dataset not found: {data_path}")

    df = pd.read_csv(data_path)

    print("=== DATA LOADING ===")
    print(f"Dataset path: {data_path}")
    print(f"Dataset shape: {df.shape}")

    return df