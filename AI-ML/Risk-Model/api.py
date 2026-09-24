from fastapi import FastAPI, HTTPException

from src.predict import predict_risk


app = FastAPI(
    title="ScaleFlow Risk Model API",
    description="AI Risk Analysis API for ScaleFlow",
    version="1.0.0",
)


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "ScaleFlow Risk Model",
    }


@app.post("/predict")
def predict_project_risk(input_data: dict):
    try:
        print("\n========== INCOMING INPUT ==========")
        print(input_data)
        print("====================================\n")

        result = predict_risk(input_data)

        print("\n========== PREDICTION RESULT ==========")
        print(result)
        print("=======================================\n")

        return result

    except Exception as e:
        import traceback

        print("\n========== ML ERROR ==========")
        traceback.print_exc()
        print("==============================\n")

        raise HTTPException(
            status_code=400,
            detail=str(e),
        )