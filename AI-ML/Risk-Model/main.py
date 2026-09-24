from pathlib import Path

import joblib
import pandas as pd

from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    balanced_accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline

from src.data_loading import load_risk_dataset
from src.cleaning import clean_risk_dataset
from src.features import prepare_features
from src.preprocessing import build_preprocessor


RANDOM_STATE = 42
TEST_SIZE = 0.20

FINAL_C = 15.0
FINAL_SOLVER = "lbfgs"


def evaluate_final_model(model, X_test, y_test):
    """
    Evaluate the final Risk model on the untouched test set.
    """

    y_pred = model.predict(X_test)

    accuracy = accuracy_score(y_test, y_pred)

    balanced_accuracy = balanced_accuracy_score(
        y_test,
        y_pred,
    )

    macro_f1 = f1_score(
        y_test,
        y_pred,
        average="macro",
    )

    weighted_f1 = f1_score(
        y_test,
        y_pred,
        average="weighted",
    )

    print("\n" + "=" * 70)
    print("FINAL RISK MODEL - TEST RESULTS")
    print("=" * 70)

    print(f"Accuracy:           {accuracy:.4f}")
    print(f"Balanced Accuracy:  {balanced_accuracy:.4f}")
    print(f"Macro F1:           {macro_f1:.4f}")
    print(f"Weighted F1:        {weighted_f1:.4f}")

    print("\n=== CLASSIFICATION REPORT ===")

    print(
        classification_report(
            y_test,
            y_pred,
            digits=4,
        )
    )

    print("=== CONFUSION MATRIX ===")

    print(
        confusion_matrix(
            y_test,
            y_pred,
        )
    )

    return {
        "accuracy": accuracy,
        "balanced_accuracy": balanced_accuracy,
        "macro_f1": macro_f1,
        "weighted_f1": weighted_f1,
    }


def save_model(model, classes):
    """
    Save the complete trained pipeline and model metadata.
    """

    project_root = Path(__file__).resolve().parent

    models_dir = project_root / "models"

    models_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    model_path = models_dir / "risk_model.joblib"

    classes_path = models_dir / "risk_classes.joblib"

    metadata_path = models_dir / "risk_model_metadata.joblib"

    # Save complete pipeline
    joblib.dump(
        model,
        model_path,
    )

    # Save class order
    joblib.dump(
        classes,
        classes_path,
    )

    # Save metadata
    metadata = {
        "model_type": "Logistic Regression",
        "C": FINAL_C,
        "solver": FINAL_SOLVER,
        "random_state": RANDOM_STATE,
        "target": "Risk_Level",
        "classes": classes.tolist(),
        "risk_score_mapping": {
            "Low": 0,
            "Medium": 33.33,
            "High": 66.67,
            "Critical": 100,
        },
    }

    joblib.dump(
        metadata,
        metadata_path,
    )

    print("\n" + "=" * 70)
    print("MODEL ARTIFACTS SAVED")
    print("=" * 70)

    print(f"Model:    {model_path}")
    print(f"Classes:  {classes_path}")
    print(f"Metadata: {metadata_path}")


def main():

    print("=" * 70)
    print("SCALEFLOW - FINAL RISK MODEL")
    print("=" * 70)

    # ============================================================
    # 1. LOAD DATA
    # ============================================================

    df = load_risk_dataset()

    # ============================================================
    # 2. CLEAN DATA
    # ============================================================

    df = clean_risk_dataset(df)

    # ============================================================
    # 3. PREPARE FEATURES
    # ============================================================

    X, y = prepare_features(df)

    # ============================================================
    # 4. TRAIN / TEST SPLIT
    # ============================================================

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=TEST_SIZE,
        random_state=RANDOM_STATE,
        stratify=y,
    )

    print("\n=== TRAIN / TEST ===")

    print(f"Train: {len(X_train)}")
    print(f"Test:  {len(X_test)}")

    # ============================================================
    # 5. BUILD PREPROCESSOR
    # ============================================================

    preprocessor = build_preprocessor(
        X_train
    )

    # ============================================================
    # 6. BUILD FINAL MODEL
    # ============================================================

    print("\n=== FINAL MODEL ===")

    print("Model: Logistic Regression")
    print(f"C: {FINAL_C}")
    print(f"Solver: {FINAL_SOLVER}")
    print("Class Weight: balanced")

    final_model = Pipeline(
        steps=[
            (
                "preprocessor",
                preprocessor,
            ),
            (
                "classifier",
                LogisticRegression(
                    C=FINAL_C,
                    solver=FINAL_SOLVER,
                    class_weight="balanced",
                    max_iter=4000,
                    random_state=RANDOM_STATE,
                ),
            ),
        ]
    )

    # ============================================================
    # 7. TRAIN
    # ============================================================

    print("\n=== TRAINING FINAL MODEL ===")

    final_model.fit(
        X_train,
        y_train,
    )

    print("Training completed.")

    # ============================================================
    # 8. FINAL TEST EVALUATION
    # ============================================================

    results = evaluate_final_model(
        final_model,
        X_test,
        y_test,
    )

    # ============================================================
    # 9. SAVE MODEL
    # ============================================================

    classifier = final_model.named_steps[
        "classifier"
    ]

    classes = classifier.classes_

    save_model(
        final_model,
        classes,
    )

    # ============================================================
    # 10. SUMMARY
    # ============================================================

    print("\n" + "=" * 70)
    print("FINAL SUMMARY")
    print("=" * 70)

    print("Selected Model: Logistic Regression")
    print(f"C: {FINAL_C}")
    print(f"Solver: {FINAL_SOLVER}")

    print(
        f"Test Accuracy: "
        f"{results['accuracy']:.4f}"
    )

    print(
        f"Test Balanced Accuracy: "
        f"{results['balanced_accuracy']:.4f}"
    )

    print(
        f"Test Macro F1: "
        f"{results['macro_f1']:.4f}"
    )

    print(
        f"Test Weighted F1: "
        f"{results['weighted_f1']:.4f}"
    )

    print("\nRisk Classes:")

    for class_name in classes:
        print(f"- {class_name}")


if __name__ == "__main__":
    main()

