from typing import Dict, Any

from fastapi import FastAPI, HTTPException

from src.predict import predict_health


app = FastAPI(
    title="ScaleFlow Health Model API",
    version="1.0.0",
)


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "ScaleFlow Health Model",
        "model_loaded": True,
    }


@app.post("/predict")
def predict(project_features: Dict[str, Any]):
    try:
        result = predict_health(project_features)

        return result

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )