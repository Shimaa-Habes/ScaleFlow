"""
eda.py
------
Step 3: look at the cleaned data before modeling.
 - how balanced are the 3 target classes?
 - what does the resolution-time distribution look like?
 - does priority or creation year relate to how fast a ticket closes?
Saves one combined chart to figures/eda_overview.png.
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

from .config import CLASS_NAMES, DURATION_CUTS_DAYS, FIGURE_DIR, display


def summarize_target(clean_df):
    """Print/show how many tickets fall into each duration class, and the
    'majority-class baseline' accuracy - i.e. the accuracy you'd get by
    always guessing the most common class. Any real model must beat this."""
    class_counts = clean_df["duration_class"].value_counts().sort_index()
    class_summary = pd.DataFrame(
        {"class": CLASS_NAMES, "count": class_counts.values, "share": (class_counts / len(clean_df)).round(3).values}
    )
    display(class_summary)
    print("Majority-class baseline accuracy:", round(class_counts.max() / len(clean_df), 3))

    # How concentrated are resolutions on just a few days? (a sign of bulk ticket-closing events)
    top_resolved = clean_df["Resolved"].dt.date.value_counts()
    print("\nShare of issues resolved on the 5 busiest days:", round(top_resolved.head(5).sum() / len(clean_df), 3))

    display(clean_df.groupby("Priority")["resolution_days"].agg(["count", "median", "mean"]).round(1).sort_values("median"))
    return class_summary


def plot_eda_overview(clean_df):
    """Draw a 2x2 grid of exploratory charts and save it as one PNG."""
    fig, axes = plt.subplots(2, 2, figsize=(14, 9))

    # Top-left: resolution time is very skewed (some tickets take years), so we
    # plot log10(days) instead of raw days, with red dashed lines marking the
    # class cut-offs (30 and 365 days) so you can see where each class begins.
    axes[0, 0].hist(np.log10(clean_df["resolution_days"].clip(lower=0.01)), bins=50)
    for cut in DURATION_CUTS_DAYS:
        axes[0, 0].axvline(np.log10(cut), color="red", linestyle="--")
    axes[0, 0].set_title("Resolution time (log10 days) with class cut-offs")
    axes[0, 0].set_xlabel("log10(days)")

    # Top-right: Created vs Resolved scatter. Horizontal bands mean many tickets
    # were all closed on the same date regardless of when they were created
    # (a sign of bulk-closing, not individual triage).
    axes[0, 1].scatter(clean_df["Created"], clean_df["Resolved"], s=6, alpha=0.5)
    axes[0, 1].set_title("Created vs Resolved: horizontal bands = bulk closing")
    axes[0, 1].set_xlabel("Created")
    axes[0, 1].set_ylabel("Resolved")

    # Bottom-left: does ticket Priority relate to how fast it gets resolved?
    pd.crosstab(clean_df["Priority"], clean_df["duration_class"]).rename(columns=dict(enumerate(CLASS_NAMES))).plot.bar(
        stacked=True, ax=axes[1, 0]
    )
    axes[1, 0].set_title("Resolution class by priority")
    axes[1, 0].set_ylabel("Issues")

    # Bottom-right: does the year a ticket was created relate to resolution class?
    pd.crosstab(clean_df["Created"].dt.year, clean_df["duration_class"]).rename(columns=dict(enumerate(CLASS_NAMES))).plot.bar(
        stacked=True, ax=axes[1, 1]
    )
    axes[1, 1].set_title("Resolution class by creation year")
    axes[1, 1].set_ylabel("Issues")

    fig.tight_layout()
    fig.savefig(FIGURE_DIR / "eda_overview.png", dpi=150)
    plt.close(fig)  # free memory; we already saved the file to disk
