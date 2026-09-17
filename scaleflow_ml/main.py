"""
ScaleFlow AI/ML Module - Entry Point
-----------------------------------------
Run this once the prepared dataset from the data preparation task is
placed at the path defined in config.RAW_DATASET_FILE.

Usage:
    python main.py                     # runs the Phase 1 / MVP tasks
    python main.py delay_prediction    # runs a single task
    python main.py performance_analysis  # Phase 2 (only once a real
                                          # health_score target exists)
"""

import sys

from config import RAW_DATASET_FILE, ALL_TASKS
from src.preprocessing import load_dataset
from src.pipeline import run_task_pipeline, run_mvp_tasks


def main():
    print(f"Loading dataset from: {RAW_DATASET_FILE}")
    df = load_dataset(RAW_DATASET_FILE)
    print(f"Dataset shape: {df.shape}")

    if len(sys.argv) > 1:
        task_name = sys.argv[1]
        if task_name not in ALL_TASKS:
            raise ValueError(f"Unknown task '{task_name}'. Valid options: {ALL_TASKS}")
        run_task_pipeline(df, task_name)
    else:
        run_mvp_tasks(df)


if __name__ == "__main__":
    main()
