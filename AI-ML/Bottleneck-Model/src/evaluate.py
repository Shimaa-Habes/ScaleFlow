"""
evaluate.py
===========
Since this is UNSUPERVISED anomaly detection, there are no ground-truth
labels to compute accuracy/precision/recall against. "Evaluation" here
instead means making the model's output inspectable and trustworthy:

    1. Attach scores/labels back onto the identifiable issue data.
    2. Rank and export the top-N most anomalous issues for human review
       (a domain expert / PM eyeballs these to sanity-check the model).
    3. Compare average feature values between flagged bottlenecks and
       normal issues, so we can explain WHY the model flagged what it
       flagged (e.g. "flagged issues have 4x the reassignment count").
    4. Write a short plain-text summary report.
"""

import pandas as pd

from config import (
    ID_COLUMNS,
    BOTTLENECK_FEATURES,
    TOP_N_FLAGGED_ISSUES,
    FLAGGED_ISSUES_PATH,
    FULL_RESULTS_PATH,
    SUMMARY_REPORT_PATH,
)


def build_results_table(original_df: pd.DataFrame, scores_labels_df: pd.DataFrame) -> pd.DataFrame:
    """
    Combine the identifier columns + raw feature values with the model's
    bottleneck_score / is_bottleneck output into one results DataFrame,
    sorted from most to least anomalous.
    """
    results = pd.concat(
        [original_df[ID_COLUMNS + BOTTLENECK_FEATURES], scores_labels_df],
        axis=1,
    )
    results = results.sort_values("bottleneck_score", ascending=False)
    return results


def get_top_flagged_issues(results_df: pd.DataFrame, top_n: int = TOP_N_FLAGGED_ISSUES) -> pd.DataFrame:
    """
    Return the top-N highest-scoring rows. These are the issues most
    worth a human review pass — the "here's where to look first" list.
    """
    return results_df.head(top_n)


def compare_flagged_vs_normal(results_df: pd.DataFrame) -> pd.DataFrame:
    """
    Build a simple explainability table: for every feature, show the
    average value among flagged bottlenecks vs. normal issues, plus the
    ratio between them. A large ratio tells us which signals are driving
    the model's decisions (useful for the presentation / exam Q&A).
    """
    grouped = results_df.groupby("is_bottleneck")[BOTTLENECK_FEATURES].mean().T
    grouped.columns = ["avg_normal", "avg_bottleneck"]

    # Avoid divide-by-zero: add a tiny epsilon when the "normal" average is 0.
    grouped["ratio_bottleneck_to_normal"] = grouped["avg_bottleneck"] / (
        grouped["avg_normal"].replace(0, 1e-9)
    )
    return grouped.sort_values("ratio_bottleneck_to_normal", ascending=False)


def write_summary_report(
    results_df: pd.DataFrame,
    comparison_df: pd.DataFrame,
    path: str = SUMMARY_REPORT_PATH,
) -> None:
    """Write a short, human-readable .txt summary of the detection run."""
    total_issues = len(results_df)
    flagged_count = int(results_df["is_bottleneck"].sum())
    flagged_pct = 100 * flagged_count / total_issues if total_issues else 0

    lines = []
    lines.append("SCALEFLOW - BOTTLENECK DETECTION SUMMARY REPORT")
    lines.append("=" * 50)
    lines.append(f"Total issues analyzed : {total_issues}")
    lines.append(f"Flagged as bottleneck  : {flagged_count} ({flagged_pct:.2f}%)")
    lines.append("")
    lines.append("Top 5 features driving anomalies (ratio = bottleneck avg / normal avg):")
    lines.append("-" * 50)
    for feature, row in comparison_df.head(5).iterrows():
        lines.append(
            f"  {feature:<30} normal={row['avg_normal']:.2f}  "
            f"bottleneck={row['avg_bottleneck']:.2f}  ratio={row['ratio_bottleneck_to_normal']:.2f}x"
        )
    lines.append("")
    lines.append(f"Full results  -> {FULL_RESULTS_PATH}")
    lines.append(f"Top flagged   -> {FLAGGED_ISSUES_PATH}")

    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def run_full_evaluation(original_df: pd.DataFrame, scores_labels_df: pd.DataFrame) -> pd.DataFrame:
    """
    End-to-end evaluation entry point called from main.py:
    builds the results table, exports CSVs, writes the summary report,
    and returns the full results DataFrame for any further inspection.
    """
    results_df = build_results_table(original_df, scores_labels_df)
    top_flagged_df = get_top_flagged_issues(results_df)
    comparison_df = compare_flagged_vs_normal(results_df)

    # Persist outputs to disk so the team can open them outside Python
    # (e.g. in Excel) for the presentation / report.
    results_df.to_csv(FULL_RESULTS_PATH, index=False)
    top_flagged_df.to_csv(FLAGGED_ISSUES_PATH, index=False)
    write_summary_report(results_df, comparison_df)

    return results_df
