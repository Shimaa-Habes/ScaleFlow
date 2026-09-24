"""
config.py
---------
All the "settings" for the project live here: file paths, random seed,
train/test sizes, and the rules used to turn resolution time (in days)
into 3 classes. Change values HERE instead of hunting through the code.
"""

import warnings
from pathlib import Path

import matplotlib
import pandas as pd

# "Agg" = draw the charts and save them as PNG files, without trying to
# pop up a window. Needed because we run this as a plain script, not Jupyter.
matplotlib.use("Agg")

# Hide harmless warnings from sklearn/pandas so the console output stays readable.
warnings.filterwarnings("ignore")

# Nicer pandas printing when a table is shown with display()/print().
pd.set_option("display.max_columns", 40)
pd.set_option("display.width", 160)

# ------------------------------- reproducibility -------------------------------
RANDOM_STATE = 42          # fixed seed -> same results every time you run the project
TEST_SIZE = 0.2            # 20% of the data is held out for final testing
CV_FOLDS = 5                # 5-fold cross-validation during model comparison/tuning
SEARCH_ITER = 20            # how many random hyperparameter combos RandomizedSearchCV tries (lower = faster)
SEARCH_SCORING = "accuracy"  # metric used to pick the best hyperparameters ("accuracy" or "f1_macro")

# ------------------------------- paths -------------------------------
# BASE_DIR = the project's root folder (one level above /src), so paths work
# no matter where you run the script from.
BASE_DIR = Path(__file__).resolve().parent.parent

CSV_PATH = BASE_DIR / "data" / "Jira_task_dataset.csv"

OUTPUT_DIR = BASE_DIR / "outputs_jira"
FIGURE_DIR = OUTPUT_DIR / "figures"   # charts (.png)
MODEL_DIR = OUTPUT_DIR / "models"     # trained model + metadata (.joblib / .json)
REPORT_DIR = OUTPUT_DIR / "reports"   # tables/metrics (.csv / .json)
DATA_DIR = OUTPUT_DIR / "data"        # the cleaned dataset (.csv)
CACHE_DIR = OUTPUT_DIR / ".cache"     # sklearn Pipeline memory cache (speeds up re-runs)

# Make sure every output folder exists before anything tries to write into it.
for folder in (FIGURE_DIR, MODEL_DIR, REPORT_DIR, DATA_DIR, CACHE_DIR):
    folder.mkdir(parents=True, exist_ok=True)

# ------------------------------- target definition -------------------------------
# Resolution time in days is cut into 3 classes at these thresholds.
# Example with the defaults: <=30 days -> class 0 (Fast), 31-365 -> class 1 (Medium), >365 -> class 2 (Slow).
DURATION_CUTS_DAYS = [30, 365]
CLASS_NAMES = ["Fast (<=30d)", "Medium (31-365d)", "Slow (>365d)"]

DROP_CREATED_BEFORE = "2019-01-01"  # drop old outlier tickets created before this date
TEXT_MAX_CHARS = 3000               # some descriptions are 30k+ characters of pasted logs; we truncate them

# display() renders a nice table in Jupyter; in a plain terminal script it doesn't exist,
# so we fall back to print() everywhere the rest of the code calls display(...).
try:
    display
except NameError:
    def display(x):
        print(x)
