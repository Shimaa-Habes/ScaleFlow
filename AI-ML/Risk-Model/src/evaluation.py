import numpy as np

from sklearn.metrics import (
    accuracy_score,
    balanced_accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
)


def evaluate_model(model, X_test, y_test, model_name):
    y_pred = model.predict(X_test)

    accuracy = accuracy_score(y_test, y_pred)
    balanced_accuracy = balanced_accuracy_score(y_test, y_pred)
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

    print(f"\n{'=' * 60}")
    print(f"MODEL: {model_name}")
    print(f"{'=' * 60}")

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
    print(confusion_matrix(y_test, y_pred))

    return {
        "model": model_name,
        "accuracy": accuracy,
        "balanced_accuracy": balanced_accuracy,
        "macro_f1": macro_f1,
        "weighted_f1": weighted_f1,
    }