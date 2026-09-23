"""
main.py
=======
Single entry point that runs the ENTIRE Bottleneck Detection pipeline
(ScaleFlow - ML Problem 3: Bottleneck Detection via Isolation Forest),
end to end:

    1. Load the raw itemlet dataset and select the curated feature set.
    2. Preprocess (cast booleans, impute missing values, scale).
    3. Train the Isolation Forest anomaly detector.
    4. Score every issue and flag the top anomalies.
    5. Export results (full scores, top-N flagged issues, summary report).
    6. Persist the trained model + preprocessor so future runs can skip
       straight to inference (see the --skip-training flag below).

USAGE
-----
    python main.py                  # train from scratch and score
    python main.py --skip-training  # reuse a previously saved model
"""

import argparse
import time

from config import DATA_PATH, MODEL_PATH, PREPROCESSOR_PATH
from src.data_loader import load_model_ready_dataframe
from src.preprocessing import BottleneckPreprocessor
from src.model import BottleneckDetector
from src.evaluate import run_full_evaluation


def parse_args() -> argparse.Namespace:
    """Command-line flags for the pipeline."""
    parser = argparse.ArgumentParser(
        description="ScaleFlow Bottleneck Detection pipeline (Isolation Forest)."
    )
    parser.add_argument(
        "--data-path",
        type=str,
        default=DATA_PATH,
        help="Path to the itemlet_dataset.csv file.",
    )
    parser.add_argument(
        "--skip-training",
        action="store_true",
        help="Load a previously saved model + preprocessor instead of retraining.",
    )
    return parser.parse_args()


def run_pipeline(data_path: str, skip_training: bool) -> None:
    pipeline_start = time.time()

    # ------------------------------------------------------------------
    # STEP 1 — LOAD DATA
    # ------------------------------------------------------------------
    print("[1/5] Loading dataset ...")
    df = load_model_ready_dataframe(path=data_path)
    print(f"      Loaded {len(df):,} issues with {df.shape[1]} columns.")

    # ------------------------------------------------------------------
    # STEP 2 — PREPROCESS
    # ------------------------------------------------------------------
    print("[2/5] Preprocessing features (impute + scale) ...")
    if skip_training:
        # Reuse a preprocessor already fitted on the original training data,
        # so new data is transformed the exact same way (no data leakage
        # from re-fitting medians/scale on a different sample).
        preprocessor = BottleneckPreprocessor.load(PREPROCESSOR_PATH)
        X = preprocessor.transform(df)
        print("      Loaded existing preprocessor from disk.")
    else:
        preprocessor = BottleneckPreprocessor()
        X = preprocessor.fit_transform(df)
        preprocessor.save(PREPROCESSOR_PATH)
        print(f"      Fitted new preprocessor and saved it to {PREPROCESSOR_PATH}")

    # ------------------------------------------------------------------
    # STEP 3 — TRAIN (OR LOAD) THE MODEL
    # ------------------------------------------------------------------
    print("[3/5] Preparing the Isolation Forest model ...")
    if skip_training:
        detector = BottleneckDetector.load(MODEL_PATH)
        print("      Loaded existing trained model from disk.")
    else:
        detector = BottleneckDetector()
        detector.fit(X)
        detector.save(MODEL_PATH)
        print(f"      Trained model and saved it to {MODEL_PATH}")

    # ------------------------------------------------------------------
    # STEP 4 — SCORE EVERY ISSUE
    # ------------------------------------------------------------------
    print("[4/5] Scoring all issues for bottleneck risk ...")
    scores_labels_df = detector.score_and_label(X)
    flagged_count = int(scores_labels_df["is_bottleneck"].sum())
    print(f"      Flagged {flagged_count:,} / {len(df):,} issues as potential bottlenecks.")

    # ------------------------------------------------------------------
    # STEP 5 — EVALUATE / EXPORT RESULTS
    # ------------------------------------------------------------------
    print("[5/5] Building reports and exporting results ...")
    run_full_evaluation(df, scores_labels_df)

    elapsed = time.time() - pipeline_start
    print(f"\nDone in {elapsed:.1f}s. See the 'outputs/' folder for results:")
    print("  - bottleneck_scores_full.csv   (every issue, scored + ranked)")
    print("  - flagged_bottlenecks.csv      (top-N highest risk issues)")
    print("  - bottleneck_summary_report.txt (human-readable summary)")


if __name__ == "__main__":
    args = parse_args()
    run_pipeline(data_path=args.data_path, skip_training=args.skip_training)
