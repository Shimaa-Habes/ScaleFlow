"""
main.py
=======
Runs the entire Jira resolution-time pipeline, start to finish:

  1. load the CSV                              (src/data_loading.py)
  2. clean the data                             (src/cleaning.py)
  3. explore it (charts + class balance)        (src/eda.py)
  4. engineer features                          (src/features.py)
  5. build train/test split + preprocessing     (src/pipelines.py)
  6. ablation study                             (src/ablation.py)
  7. compare models with cross-validation       (src/model_selection.py)
  8. tune hyperparameters + build an ensemble   (src/model_selection.py)
  9. evaluate the final model on the test set   (src/evaluation.py)
 10. time-shift check                           (src/evaluation.py)
 11. save the model, reports and predictions    (src/save_artifacts.py)
 12. demo: predict on a few new tickets         (src/predict.py)

Just run:   python main.py
Everything gets saved under outputs_jira/ (figures, models, reports, data).
"""

import pandas as pd
from sklearn.model_selection import StratifiedKFold, train_test_split

from src import ablation, eda, evaluation, model_selection, save_artifacts
from src.cleaning import clean_data
from src.config import CV_FOLDS, DATA_DIR, RANDOM_STATE, REPORT_DIR, TEST_SIZE, display
from src.data_loading import load_raw_data, quality_overview
from src.features import build_feature_matrix
from src.predict import predict_resolution_class


def main():
    # ---------- 1-2. load + clean ----------
    print("\n=== 1. Loading data ===")
    raw_df = load_raw_data()
    quality_before = quality_overview(raw_df)
    display(quality_before.to_frame())

    print("\n=== 2. Cleaning data ===")
    clean_df = clean_data(raw_df)
    quality_after = quality_overview(clean_df.assign(Status="Done"))
    print(f"Rows before: {len(raw_df)} | rows after cleaning: {len(clean_df)}")

    clean_df.to_csv(DATA_DIR / "Jira_task_dataset_clean.csv", index=False, encoding="utf-8-sig")
    pd.concat([quality_before.rename("before"), quality_after.rename("after")], axis=1).to_csv(
        REPORT_DIR / "data_quality_report.csv"
    )
    display(clean_df[["Summary", "Priority", "Created", "Resolved", "Labels", "resolution_days", "duration_class"]].head())

    # ---------- 3. EDA ----------
    print("\n=== 3. Exploratory analysis ===")
    eda.summarize_target(clean_df)
    eda.plot_eda_overview(clean_df)

    # ---------- 4. features ----------
    print("\n=== 4. Feature engineering ===")
    X, y = build_feature_matrix(clean_df)

    # ---------- 5. split ----------
    print("\n=== 5. Train/test split ===")
    X_train, X_test, y_train, y_test, idx_train, idx_test = train_test_split(
        X, y, clean_df.index, test_size=TEST_SIZE, stratify=y, random_state=RANDOM_STATE
    )
    print("Train:", X_train.shape, "| Test:", X_test.shape)
    print("Train class shares:", y_train.value_counts(normalize=True).sort_index().round(3).to_dict())
    cv = StratifiedKFold(n_splits=CV_FOLDS, shuffle=True, random_state=RANDOM_STATE)

    # ---------- 6. ablation ----------
    print("\n=== 6. Ablation study ===")
    ablation_table = ablation.run_ablation(X_train, y_train, cv)

    # ---------- 7. compare models ----------
    print("\n=== 7. Model comparison ===")
    comparison, candidates = model_selection.compare_models(X_train, y_train, cv)

    # ---------- 8. tune + ensemble ----------
    print("\n=== 8. Hyperparameter tuning ===")
    tuned, tuning_table = model_selection.tune_models(X_train, y_train, cv)
    ensemble = model_selection.build_ensemble(tuned)
    best_model, best_name, final_candidates, final_comparison = model_selection.select_best_model(
        tuned, ensemble, X_train, y_train, cv
    )

    # ---------- 9. final evaluation ----------
    print("\n=== 9. Final evaluation on held-out test set ===")
    y_pred, y_proba, test_metrics, report_df = evaluation.evaluate_on_test_set(best_model, X_test, y_test, X_train, y_train)
    importance_df = evaluation.permutation_importance_report(best_model, X_test, y_test)

 
    # ---------- 11. save everything ----------
    print("\n=== 11. Saving model, reports and predictions ===")
    save_artifacts.save_model_and_metadata(best_model)
    save_artifacts.save_predictions_and_report(
        clean_df, idx_test, y_test, y_pred, y_proba, best_model, importance_df, report_df, raw_df,
        X_train, X_test, ablation_table, comparison, tuning_table, final_comparison, best_name,
        test_metrics,
    )

    # ---------- 12. demo prediction on a few tickets ----------
    print("\n=== 12. Demo: predicting on a few (held-out) tickets ===")
    sample = clean_df.loc[idx_test[:5], ["Summary", "Description", "Labels", "Priority", "Created"]]
    preds = predict_resolution_class(sample, model=best_model)
    display(pd.concat([sample[["Summary"]].reset_index(drop=True), preds.reset_index(drop=True)], axis=1))

    print("\nDone. All outputs are in the outputs_jira/ folder.")


if __name__ == "__main__":
    main()