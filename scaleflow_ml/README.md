# ScaleFlow — AI/ML Modeling Structure

This is the initial AI/ML modeling setup for **ScaleFlow** (Enterprise Project
Intelligence Platform), built directly from the **ScaleFlow AI/ML Model Approach**
document (BinX Tech, Team 4, 14 September 2026) and the **ScaleFlow Project
Analysis & Proposal** (BinX Tech, 2026).

It covers the four ML problems defined in the Model Approach document:

1. **Task Delay Prediction** — Binary Classification — Random Forest Classifier
2. **Risk Analysis** — Classification — Random Forest Classifier
3. **Bottleneck Detection** — Anomaly Detection — Isolation Forest
4. **Project Performance / Health Analysis** — Regression — Random Forest
   Regressor (**Phase 2**, deferred until a real numerical health target exists)

Per Section 11 of the Model Approach document, the **Phase 1 / MVP** scope is
Task Delay Prediction, Risk Analysis, and Bottleneck Detection. Performance
Analysis is prepared but intentionally excluded from the default run.

---

## 1. Project Structure

```
scaleflow_ml/
├── config.py                       # Global paths, random seed, task constants
├── main.py                         # Entry point to run the pipelines
├── requirements.txt                 # Python libraries needed
├── data/
│   ├── raw/                        # Place the prepared dataset here
│   └── processed/                  # Reserved for intermediate processed data
├── artifacts/
│   ├── models/                     # Trained model files (.joblib) are saved here
│   └── reports/                    # Evaluation reports (JSON + text) are saved here
├── notebooks/                      # Jupyter notebook version of this setup
└── src/
    ├── features.py                  # Input/target schema for each ML problem
    ├── preprocessing.py             # Data loading, leakage guard, preprocessing
    ├── training.py                  # Reusable training / CV / tuning / saving
    ├── evaluation.py                # Reusable evaluation + reporting functions
    ├── pipeline.py                   # Orchestrates each task end-to-end
    └── models/
        ├── delay_prediction.py       # Task Delay Prediction — Random Forest
        ├── risk_analysis.py          # Risk Analysis — Random Forest
        ├── bottleneck_detection.py   # Bottleneck Detection — Isolation Forest
        └── performance_analysis.py   # Performance Analysis — Random Forest (Phase 2)
```

Each ML problem has its own model file under `src/models/`, but all four share
the same preprocessing, training, and evaluation utilities — consistent with
the shared "feature engineering → model → intelligence layer" flow described
in Section 9 of the Model Approach document.

---

## 2. Environment & Libraries

Install with:

```bash
pip install -r requirements.txt
```

| Library | Purpose |
|---|---|
| `pandas`, `numpy` | Data loading and manipulation |
| `scikit-learn` | Preprocessing, Random Forest Classifier/Regressor, Isolation Forest, evaluation metrics |
| `joblib` | Saving and loading trained models |
| `matplotlib`, `seaborn` | Visualization for EDA and evaluation |
| `jupyter`, `nbformat` | Notebook environment |

The library list is intentionally scoped to what the Model Approach document
recommends (tree-based, interpretable models), all available in `scikit-learn`.

---

## 3. Input & Target Definition per ML Problem

All feature/target definitions live in `src/features.py`, taken directly from
Sections 4–7 of the Model Approach document.

### 3.1 Task Delay Prediction (Section 4)
- **Problem type:** Binary classification
- **Target:** `is_delayed` — 1 if the actual finish date is after the planned
  due date, 0 otherwise
- **Numeric inputs:** progress percentage, estimated duration, days until
  deadline, task age, dependency count, delayed dependency count, workload
  ratio, active tasks count, historical delay rate, average completion time
- **Categorical inputs:** task status, priority, blocked status

### 3.2 Risk Analysis (Section 5)
- **Problem type:** Classification (Low / Medium / High), with a regression
  alternative (`build_risk_score_regressor`) if the dataset instead provides a
  continuous `risk_score`
- **Inputs, grouped exactly as in the document:**
  - Schedule: delay probability, overdue task ratio, milestone status
  - Progress: project progress, progress variance
  - Dependencies: blocked tasks, delayed dependency count
  - Resources: workload ratio, team size, overloaded members
  - History: historical project delay rate, previous risk outcomes

### 3.3 Bottleneck Detection (Section 6)
- **Problem type:** Anomaly detection (unsupervised — no labeled data exists)
- **Inputs:** task duration, completion velocity, blocked duration, dependency
  count, delayed dependency count, workload ratio, number of dependent tasks,
  historical completion time

### 3.4 Project Performance / Health Analysis (Section 7) — Phase 2
- **Problem type:** Regression
- **Target:** `health_score` — must not be fabricated; wait for a real
  numerical target
- **Inputs:** project progress percentage, overdue/completed/blocked task
  counts, workload ratio, team size, historical delay rate, progress
  variance, completion velocity, milestone status

---

## 4. Preprocessing Steps

Implemented in `src/preprocessing.py`:

1. **Load & deduplicate** — read the CSV dataset, drop exact duplicate rows.
2. **Column validation** — `basic_data_checks()` confirms all required
   feature and target columns exist before training starts.
3. **Leakage guard** — `check_no_leakage()` raises an error if any of
   `completed_date`, `actual_duration`, or `final_delay_days` appear in the
   Task Delay Prediction feature list, per Section 10 of the Model Approach
   document. These fields exist only to construct the label after the fact.
4. **Numeric preprocessing** — median imputation, then standard scaling.
5. **Categorical preprocessing** — constant `"missing"` imputation, then
   one-hot encoding (`handle_unknown="ignore"`).
6. **Train/test split** — stratified 80/20 split for classification tasks;
   plain 80/20 split for the Performance regressor. Not applicable to
   Bottleneck Detection (unsupervised, trained on the full feature set).

All preprocessing is wrapped inside each model's `Pipeline`, so imputers,
scalers, and encoders are fit only on training data.

---

## 5. Model Pipelines

| Task | Problem Type | Model | Main Output |
|---|---|---|---|
| Task Delay Prediction | Binary Classification | Random Forest Classifier | Delay probability + delayed/on-time label |
| Risk Analysis | Classification | Random Forest Classifier | Risk probability + risk level |
| Bottleneck Detection | Anomaly Detection | Isolation Forest | Bottleneck/anomaly score |
| Performance Analysis (Phase 2) | Regression | Random Forest Regressor | Performance/health score |

Each `src/models/*.py` file exposes a `build_*_model()` function returning a
ready-to-train `Pipeline`, plus a `*_HYPERPARAMETER_GRID` for later tuning.

---

## 6. Reusable Training & Evaluation Functions

**`src/training.py`**
- `train_model(pipeline, X_train, y_train=None)` — fits classification,
  regression, or unsupervised pipelines (y omitted for Bottleneck Detection).
- `cross_validate_model()` / `cross_validate_regressor()` — quick CV checks.
- `tune_hyperparameters()` — grid search with stratified CV.
- `save_model()` / `load_model()` — persist/load trained pipelines.

**`src/evaluation.py`** — metrics match Sections 4, 5, 6, 7 of the Model
Approach document exactly:
- `evaluate_classification()` — Precision, Recall, F1, ROC-AUC, Accuracy
  (secondary), Confusion Matrix. Used for Delay Prediction and Risk Analysis.
- `evaluate_bottleneck_detection()` — anomaly score + flagged bottleneck
  count, with a note that Precision/Recall apply only once labeled bottleneck
  outcomes exist; until then, evaluation relies on manual validation.
- `evaluate_regression()` — MAE, RMSE, R². Used for Performance Analysis.
- `save_evaluation_report()` / `print_summary()` — persist and print results.

---

## 7. Orchestration (`src/pipeline.py`)

`run_task_pipeline(df, task_name)` runs one task end-to-end, branching by
`problem_type`:

```
validate columns → check for leakage → split X/y → build model
   → (classification/regression: train/test split + CV)
   → (anomaly detection: fit on full X, no split)
   → train → evaluate → save model + report
```

`run_mvp_tasks(df)` runs the three Phase 1 tasks (Delay Prediction, Risk
Analysis, Bottleneck Detection) in sequence, matching Section 11 of the
Model Approach document. Performance Analysis is intentionally excluded from
this default run.

---

## 8. How to Run Once the Dataset Is Ready

1. Place the prepared dataset (CSV) at:
   ```
   data/raw/scaleflow_tasks_dataset.csv
   ```
   (or update `RAW_DATASET_FILE` in `config.py`).
2. Confirm the dataset contains all columns listed in `src/features.py` for
   each task, including the target columns `is_delayed` and `risk_level`
   (or `risk_score`). Bottleneck Detection needs no target column.
3. Install dependencies: `pip install -r requirements.txt`
4. Run the Phase 1 / MVP tasks:
   ```bash
   python main.py
   ```
   Or run a single task:
   ```bash
   python main.py delay_prediction
   python main.py risk_analysis
   python main.py bottleneck_detection
   ```
5. Trained models will appear in `artifacts/models/`, and evaluation reports
   in `artifacts/reports/`.

---

## 9. Next Steps for Training

- **Data validation pass:** once the real dataset arrives, run
  `basic_data_checks()` and `check_no_leakage()` first to confirm column
  names match and no leakage fields slipped into the feature list.
- **Exploratory Data Analysis (EDA):** use the `notebooks/` folder to check
  class balance (delayed vs. on-time, risk levels), missing-value rates, and
  feature distributions before full training.
- **Baseline training run:** execute `python main.py` for a first pass on
  the three MVP tasks and establish a baseline to improve on.
- **Bottleneck validation loop:** have project managers manually review the
  flagged bottleneck cases from Isolation Forest; once enough validated
  outcomes accumulate, treat it as a labeled dataset and switch to
  Precision/Recall evaluation via `evaluate_classification()`.
- **Hyperparameter tuning:** use `tune_hyperparameters()` with the grids
  provided in each model file once baseline results are available.
- **Risk Analysis target check:** confirm with the data preparation task
  whether `risk_level` (classification) or `risk_score` (regression) is the
  actual target being produced, and switch to `build_risk_score_regressor()`
  if it is the latter.
- **Performance Analysis (Phase 2):** do not train this model until a real,
  non-fabricated `health_score` exists. Until then, the platform can
  calculate an initial health indicator directly from defined project KPIs,
  as noted in Section 7 of the Model Approach document.
- **System integration:** once a model is finalized, wrap `load_model()` +
  `pipeline.predict()` inside the backend's AI/ML Engine service so the
  Generative AI layer can consume predictions in real time (Section 9 of the
  Model Approach document; Section 6 of the Project Proposal).

---

## References
- ScaleFlow — Project Analysis & Proposal. BinX Tech, 2026.
- ScaleFlow — AI/ML Model Approach. BinX Tech, Team 4, 14 September 2026.
