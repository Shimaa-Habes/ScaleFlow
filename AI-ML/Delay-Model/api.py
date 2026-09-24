from datetime import datetime
from typing import Optional

import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from src.predict import load_model, predict_resolution_class


app = FastAPI(
    title="ScaleFlow Delay Model API",
    version="1.0.0",
)


class DelayTaskRequest(BaseModel):
    task_id: int
    summary: str
    description: Optional[str] = ""
    labels: Optional[str] = ""
    priority: Optional[str] = "Unknown"
    created: Optional[datetime] = None


@app.get("/health")
def health_check():
    """
    Check whether the Delay ML API is running
    and the saved model can be loaded.
    """

    try:
        load_model()

        return {
            "status": "ok",
            "service": "ScaleFlow Delay Model",
            "model_loaded": True,
        }

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"Model loading failed: {error}",
        )


@app.post("/predict")
def predict_delay(request: DelayTaskRequest):
    """
    Predict the resolution-time class for a ScaleFlow task.
    """

    try:
        created = request.created or datetime.now()

        input_data = pd.DataFrame(
            [
                {
                    "Summary": request.summary,
                    "Description": request.description or "",
                    "Labels": request.labels or "",
                    "Priority": request.priority or "Unknown",
                    "Created": created,
                }
            ]
        )

        prediction = predict_resolution_class(input_data)

        row = prediction.iloc[0]

        probabilities = {
            "fast": float(row["prob_Fast (<=30d)"]),
            "medium": float(row["prob_Medium (31-365d)"]),
            "slow": float(row["prob_Slow (>365d)"]),
        }

        predicted_class = str(row["predicted_class"])

        if predicted_class.startswith("Fast"):
            delay_level = "Low"
        elif predicted_class.startswith("Medium"):
            delay_level = "Medium"
        else:
            delay_level = "High"

        return {
            "task_id": request.task_id,
            "predicted_class": predicted_class,
            "delay_level": delay_level,
            "probabilities": probabilities,
        }

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )