# ScaleFlow — Bottleneck Detection (Isolation Forest)

Unsupervised anomaly-detection pipeline for ML Problem 3 (Bottleneck
Detection) in the ScaleFlow Enterprise Project Intelligence Platform.
Isolation Forest is used instead of a supervised model because there is
no labeled "this issue was a bottleneck" ground truth in the dataset.

## Project structure

```
bottleneck_detection/
├── README.md                  # this file
├── requirements.txt           # Python dependencies
├── config.py                  # paths, feature lists, model hyperparameters
├── main.py                    # entry point — runs the full pipeline
├── data/
│   └── itemlet_dataset.csv    # (place the raw dataset here — not included)
├── models/                    # trained model + preprocessor are saved here
│   ├── bottleneck_isolation_forest.joblib
│   └── bottleneck_preprocessor.joblib
├── outputs/                   # results are written here after each run
│   ├── bottleneck_scores_full.csv
│   ├── flagged_bottlenecks.csv
│   └── bottleneck_summary_report.txt
└── src/
    ├── __init__.py
    ├── data_loader.py         # loads the CSV, selects/validates required columns
    ├── preprocessing.py       # BottleneckPreprocessor: impute + scale features
    ├── model.py                # BottleneckDetector: Isolation Forest wrapper
    └── evaluate.py             # builds results table, top-N flags, summary report
```

## What each file does

| File | Purpose |
|---|---|
| `config.py` | Single source of truth: file paths, the curated bottleneck feature list (grouped: time/duration, process friction, dependency/connectivity, collaboration, rework/status), the excluded leakage features (documented, not used), and the Isolation Forest hyperparameters. |
| `src/data_loader.py` | Reads `itemlet_dataset.csv` and keeps only the identifier + feature columns the model needs. Fails fast with a clear error if a required column is missing. |
| `src/preprocessing.py` | `BottleneckPreprocessor` class — casts boolean columns to 0/1, median-imputes missing values (e.g. `Cycle Time`, `Total Days`, `issue_age_days` are NaN for unresolved issues), then standardizes all features. Saveable/loadable with `joblib` so the exact same transformation can be replayed at inference time. |
| `src/model.py` | `BottleneckDetector` class — wraps `sklearn.ensemble.IsolationForest`. Converts sklearn's raw (and easy-to-misread) decision function into an intuitive `bottleneck_score` (higher = more anomalous) and a binary `is_bottleneck` flag. |
| `src/evaluate.py` | Builds the ranked results table, exports the top-N most anomalous issues, compares average feature values between flagged and normal issues (for explainability), and writes a plain-text summary report. |
| `main.py` | Orchestrates all of the above into one runnable pipeline. |

## How to run

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
2. Place `itemlet_dataset.csv` inside the `data/` folder.
3. Run the full pipeline (trains a new model):
   ```bash
   python main.py
   ```
4. On later runs, skip retraining and reuse the saved model:
   ```bash
   python main.py --skip-training
   ```

## Output

After a run, check the `outputs/` folder:

- **`bottleneck_scores_full.csv`** — every issue, with its `bottleneck_score` and `is_bottleneck` flag, sorted from most to least anomalous.
- **`flagged_bottlenecks.csv`** — the top-N highest-risk issues (shortlist for human review).
- **`bottleneck_summary_report.txt`** — flagged count/percentage plus the top features driving the anomaly scores.

## Why Isolation Forest

No labeled bottleneck data exists in the Data Requirements document, so
this is framed as unsupervised anomaly detection. Isolation Forest
isolates anomalies by random feature-space partitioning — issues with
unusual combinations of cycle time, rework, dependency load, etc.
require fewer random splits to isolate than normal issues, which
matches the intuition of "an issue behaving very differently from the
rest of the backlog."

, and the Isolation Forest is a good fit for this task.

## Run

To run the code, you'll need to install the required packages:

```bash
pip install -r requirements.txt
```

Then, you can run the code with the following command:
<uvicorn api:app --host 0.0.0.0 --port 8000 --reload>