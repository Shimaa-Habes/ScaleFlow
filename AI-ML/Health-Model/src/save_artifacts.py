from pathlib import Path
import joblib


MODEL_DIR = (
    Path(__file__).resolve().parents[1]
    / "models"
)


def save_model(
    model,
    filename: str,
):
    """
    Save a trained model to the models directory.
    """

    # Create the models directory if it does not exist.
    MODEL_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    path = MODEL_DIR / filename

    joblib.dump(
        model,
        path,
    )

    print(f"Saved model: {path}")


def save_artifact(
    artifact,
    filename: str,
):
    """
    Save preprocessing artifacts such as imputers and scalers.
    """

    MODEL_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    path = MODEL_DIR / filename

    joblib.dump(
        artifact,
        path,
    )

    print(f"Saved artifact: {path}")