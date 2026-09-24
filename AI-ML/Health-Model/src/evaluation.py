from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
    classification_report,
)


def evaluate_model(
    model,
    X_test,
    y_test,
    model_name,
):
    """
    Evaluate a trained classification model.
    """

    print(f"\n=== {model_name.upper()} EVALUATION ===")

    # Generate class predictions.
    predictions = model.predict(X_test)

    # Generate probabilities for the failed-budget class.
    probabilities = model.predict_proba(X_test)[:, 1]

    accuracy = accuracy_score(
        y_test,
        predictions,
    )

    precision = precision_score(
        y_test,
        predictions,
        zero_division=0,
    )

    recall = recall_score(
        y_test,
        predictions,
        zero_division=0,
    )

    f1 = f1_score(
        y_test,
        predictions,
        zero_division=0,
    )

    auc = roc_auc_score(
        y_test,
        probabilities,
    )

    print(f"Accuracy:  {accuracy:.4f}")
    print(f"Precision: {precision:.4f}")
    print(f"Recall:    {recall:.4f}")
    print(f"F1 Score:  {f1:.4f}")
    print(f"ROC-AUC:   {auc:.4f}")

    print("\nClassification Report:")
    print(
        classification_report(
            y_test,
            predictions,
            zero_division=0,
        )
    )

    return {
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "f1": f1,
        "roc_auc": auc,
    }