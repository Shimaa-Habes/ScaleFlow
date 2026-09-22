# Jira Resolution-Time Pipeline

Predicts how long a Jira ticket will take to resolve — **Fast (≤30 days)**,
**Medium (31–365 days)**, or **Slow (>365 days)** — from its Summary,
Description, Labels, Priority and creation time. Includes a bonus regression
model that predicts the exact number of days.

This is the same pipeline as the original notebook (`jira_risk_pipeline.ipynb`),
split into organized, commented `.py` files. The Excel→CSV conversion step was
removed since the project now reads `Jira_task_dataset.csv` directly.

## Folder structure

```
jira_risk_pipeline/
├── main.py                 # run this — executes the full pipeline top to bottom
├── requirements.txt        # pip install -r requirements.txt
├── data/
│   └── Jira_task_dataset.csv   # your input data (put it here)
├── src/
│   ├── config.py            # paths, constants, random seed
│   ├── data_loading.py      # load CSV + data-quality overview
│   ├── cleaning.py          # text cleaning, dedup, target creation
│   ├── eda.py                # exploratory charts + class balance
│   ├── features.py           # raw columns -> model features
│   ├── pipelines.py          # sklearn preprocessing pipelines (sparse/dense)
│   ├── ablation.py           # which feature groups matter
│   ├── model_selection.py    # model comparison, tuning, ensemble
│   ├── evaluation.py         # test metrics, confusion matrix, importance, time-shift check
│   ├── regression.py         # bonus: predict exact resolution days
│   ├── save_artifacts.py     # save model, metadata, predictions, report
│   └── predict.py            # load the saved model and predict on new tickets
└── outputs_jira/             # created automatically when you run main.py
    ├── data/                 # cleaned dataset
    ├── figures/               # PNG charts
    ├── models/                # trained model (.joblib) + metadata (.json)
    └── reports/                # CSV/JSON metrics and predictions
```

## How to run

```bash
pip install -r requirements.txt
python main.py
```

Everything prints progress to the console and saves results into
`outputs_jira/`. A full run (model comparison + hyperparameter tuning) can
take a few minutes depending on your machine — lower `SEARCH_ITER` or
`CV_FOLDS` in `src/config.py` to speed it up.

## Using the trained model later

```python
import pandas as pd
from src.predict import predict_resolution_class

new_tickets = pd.DataFrame({
    "Summary": ["Login page throws 500 error"],
    "Description": ["Users can't log in, stack trace attached..."],
    "Labels": ["bug,login"],
    "Priority": ["High"],
    "Created": ["2026-01-15 10:00:00"],
})

print(predict_resolution_class(new_tickets))
```

## Notes

- Every function has a short comment explaining what it does and why
  (especially the less-obvious lines: regex patterns, `np.digitize` class
  cutting, `TruncatedSVD` text compression, soft-voting ensembles,
  permutation importance, and the log-scale regression target).
- Config values (random seed, test size, cross-validation folds, class
  cut-offs in days) live in one place: `src/config.py`.
