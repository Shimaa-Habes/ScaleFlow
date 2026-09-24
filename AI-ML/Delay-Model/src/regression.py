"""
regression.py
-------------
Step 12 (bonus): instead of just predicting a class (Fast/Medium/Slow),
try to predict the actual number of days until resolution as a continuous
number, using a few regression models.
"""

import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingRegressor, RandomForestRegressor
from sklearn.linear_model import Ridge
from sklearn.metrics import accuracy_score, mean_absolute_error, median_absolute_error, r2_score

from .config import DURATION_CUTS_DAYS, RANDOM_STATE, REPORT_DIR, display
from .pipelines import dense_pipeline, sparse_pipeline


def run_regression(clean_df, X_train, X_test, idx_train, idx_test, y_test):
    """Train a few regressors on log(1 + days) and evaluate them on the real day scale."""
    y_days = clean_df["resolution_days"]
    days_train, days_test = y_days.loc[idx_train], y_days.loc[idx_test]

    reg_models = {
        "Ridge": sparse_pipeline(Ridge(alpha=3.0)),
        "Random Forest": dense_pipeline(RandomForestRegressor(n_estimators=400, min_samples_leaf=2, n_jobs=-1, random_state=RANDOM_STATE)),
        "Hist Gradient Boosting": dense_pipeline(HistGradientBoostingRegressor(learning_rate=0.05, max_iter=400, random_state=RANDOM_STATE)),
    }

    reg_rows = []
    for name, model in reg_models.items():
        # np.log1p(days) = log(1 + days). Resolution time is heavily right-skewed
        # (a few tickets take years), so training on the log scale stops those
        # extreme values from dominating the loss function.
        model.fit(X_train, np.log1p(days_train))
        # np.expm1 undoes log1p to get back to real days; .clip(min=0) guards against
        # any tiny negative prediction that would make no physical sense.
        pred_days = np.expm1(model.predict(X_test)).clip(min=0)

        reg_rows.append(
            {
                "model": name,
                "MAE_days": mean_absolute_error(days_test, pred_days),
                "median_AE_days": median_absolute_error(days_test, pred_days),
                "R2_days": r2_score(days_test, pred_days),
                "R2_log_days": r2_score(np.log1p(days_test), np.log1p(pred_days)),
                # Bonus sanity check: if we bucket the *predicted days* using the same
                # cut-offs as the classifier, how often does that match the true class?
                "class_accuracy_from_days": accuracy_score(y_test, np.digitize(pred_days, DURATION_CUTS_DAYS, right=True)),
            }
        )

    regression_table = pd.DataFrame(reg_rows).set_index("model")
    display(regression_table.round(3))
    regression_table.to_csv(REPORT_DIR / "regression_results.csv")
    return regression_table
