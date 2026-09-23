"""
api.py
======
The "bridge" between the trained Python/scikit-learn Bottleneck
Detection model and any external application (e.g. the ScaleFlow .NET
backend). The .NET side cannot open a .joblib file directly (those are
Python pickle objects), so this small FastAPI service loads the
trained preprocessor + model ONCE and exposes them over plain HTTP/JSON,
which any language/stack can call.

IMPORTANT: this service does NOT train anything. It only loads the
artifacts produced by `python main.py` (bottleneck_preprocessor.joblib
and bottleneck_isolation_forest.joblib). Run main.py at least once
before starting this API.

RUNNING THE SERVER
-------------------
    uvicorn api:app --host 0.0.0.0 --port 8000 --reload

Interactive docs (Swagger UI) are then available at:
    http://localhost:8000/docs
"""

from contextlib import asynccontextmanager
from typing import List, Optional

import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field, ConfigDict

from config import MODEL_PATH, PREPROCESSOR_PATH
from src.model import BottleneckDetector
from src.preprocessing import BottleneckPreprocessor

# ---------------------------------------------------------------------------
# GLOBAL MODEL STATE
# ---------------------------------------------------------------------------
# A tiny container object instead of bare global variables — this avoids
# "global" statements scattered through the endpoint functions and makes
# it obvious, in one place, what state the whole app depends on.
class ModelState:
    preprocessor: Optional[BottleneckPreprocessor] = None
    detector: Optional[BottleneckDetector] = None


model_state = ModelState()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    FastAPI lifespan hook: code before 'yield' runs ONCE when the server
    starts (load the model into memory), code after 'yield' runs ONCE
    when the server shuts down (nothing to clean up here, but the hook
    is the modern replacement for the deprecated @app.on_event pattern).

    Loading the model at startup — instead of inside every request — is
    what makes each /predict call fast: no disk I/O per request.
    """
    try:
        model_state.preprocessor = BottleneckPreprocessor.load(PREPROCESSOR_PATH)
        model_state.detector = BottleneckDetector.load(MODEL_PATH)
    except FileNotFoundError as exc:
        # Fail loudly at startup rather than on the first request — the
        # team should know immediately if main.py hasn't been run yet.
        raise RuntimeError(
            "Could not load a trained model/preprocessor. "
            "Run 'python main.py' at least once before starting the API."
        ) from exc
    yield
    # Nothing to release on shutdown (no open connections/files kept alive).


app = FastAPI(
    title="ScaleFlow Bottleneck Detection API",
    description="Serves the trained Isolation Forest bottleneck-detection model over HTTP.",
    version="1.0.0",
    lifespan=lifespan,
)


# ---------------------------------------------------------------------------
# REQUEST / RESPONSE SCHEMAS
# ---------------------------------------------------------------------------
# Every field below maps to one of the 26 columns in config.BOTTLENECK_FEATURES.
# The raw CSV column names contain spaces and parentheses (e.g.
# "Cycle Time (hours)"), which are not valid Python identifiers, so each
# field has a Python-friendly name AND a Field(alias=...) matching the
# exact original column name. `populate_by_name=True` lets callers send
# EITHER the alias ("Cycle Time (hours)") or the snake_case name
# (cycle_time_hours) — whichever is easier for the .NET client to produce.
class IssueFeatures(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    # --- time / duration -------------------------------------------------
    cycle_time_hours: Optional[float] = Field(default=None, alias="Cycle Time (hours)")
    total_days: Optional[float] = Field(default=None, alias="Total Days")
    issue_age_days: Optional[float] = Field(default=None, alias="issue_age_days")
    total_time_logged_hours: float = Field(alias="Total Time Logged (hours)")
    worklog_total: Optional[float] = Field(default=None, alias="worklog_total")
    worklog_count: int = Field(alias="Worklog Count")

    # --- process friction --------------------------------------------------
    transition_count: int = Field(alias="Transition Count")
    reassignment_count: int = Field(alias="Reassignment Count")
    reopen_count: int = Field(alias="Reopen Count")
    priority_changes: int = Field(alias="Priority Changes")
    process_overhead: int = Field(alias="process_overhead")
    handoff_complexity: int = Field(alias="handoff_complexity")

    # --- dependencies / connectivity ---------------------------------------
    blocking_issues: int = Field(alias="Blocking Issues")
    blocked_by_issues: int = Field(alias="Blocked By Issues")
    number_of_inward_links: int = Field(alias="Number of Inward Links")
    number_of_outward_links: int = Field(alias="Number of Outward Links")
    dependency_complexity: int = Field(alias="dependency_complexity")
    coordination_complexity: float = Field(alias="coordination_complexity")

    # --- collaboration -------------------------------------------------
    work_sessions: int = Field(alias="work_sessions")
    comment_count: int = Field(alias="comment_count")
    communication_overhead: int = Field(alias="communication_overhead")
    collaboration_intensity: int = Field(alias="collaboration_intensity")

    # --- rework / status signals --------------------------------------
    rework_indicator: bool = Field(alias="rework_indicator")
    has_rework: bool = Field(alias="has_rework")
    is_long_running: bool = Field(alias="is_long_running")
    is_stale: int = Field(alias="is_stale")


class IssueRequest(IssueFeatures):
    """
    Everything IssueFeatures has, PLUS optional identifier fields.
    These are never used by the model — they are only echoed back in
    the response so the caller (.NET backend) can match a prediction
    to the right issue without maintaining its own row order.
    """
    issue_key: Optional[str] = None
    issue_summary: Optional[str] = None
    project_key: Optional[str] = None
    status_name: Optional[str] = None
    priority_name: Optional[str] = None


class PredictionResponse(BaseModel):
    issue_key: Optional[str] = None
    bottleneck_score: float
    is_bottleneck: int
    label: str  # human-readable: "Bottleneck" or "Normal"


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool


# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------
def _score_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    """
    Shared scoring logic used by both the single and batch endpoints:
    preprocess with the SAVED (already-fitted) preprocessor, then score
    with the SAVED (already-trained) model. Never re-fits anything.
    """
    if model_state.preprocessor is None or model_state.detector is None:
        # Defensive check — should not happen if lifespan() succeeded,
        # but guards against calling the API in a broken state.
        raise HTTPException(status_code=503, detail="Model is not loaded yet.")

    X = model_state.preprocessor.transform(df)
    return model_state.detector.score_and_label(X)


def _build_response(issue_key: Optional[str], score: float, label_flag: int) -> PredictionResponse:
    return PredictionResponse(
        issue_key=issue_key,
        bottleneck_score=round(float(score), 6),
        is_bottleneck=int(label_flag),
        label="Bottleneck" if label_flag == 1 else "Normal",
    )


# ---------------------------------------------------------------------------
# ENDPOINTS
# ---------------------------------------------------------------------------
@app.get("/health", response_model=HealthResponse)
def health_check() -> HealthResponse:
    """Simple liveness/readiness check — useful for the .NET side to ping before calling /predict."""
    return HealthResponse(
        status="ok",
        model_loaded=model_state.preprocessor is not None and model_state.detector is not None,
    )


@app.post("/predict", response_model=PredictionResponse)
def predict_single(issue: IssueRequest) -> PredictionResponse:
    """
    Score ONE issue and return its bottleneck score + flag.
    Typical use: the .NET backend calls this right after an issue is
    updated, to refresh its bottleneck risk in near real time.
    """
    # by_alias=True so the DataFrame's column names match the ORIGINAL
    # feature names the preprocessor was fitted on (e.g. "Cycle Time (hours)").
    row = issue.model_dump(by_alias=True)
    df = pd.DataFrame([row])

    scored = _score_dataframe(df)
    return _build_response(issue.issue_key, scored["bottleneck_score"].iloc[0], scored["is_bottleneck"].iloc[0])


@app.post("/predict/batch", response_model=List[PredictionResponse])
def predict_batch(issues: List[IssueRequest]) -> List[PredictionResponse]:
    """
    Score MANY issues in one call — far more efficient than calling
    /predict in a loop, since preprocessing/scoring run once on the
    whole batch instead of once per issue. Typical use: a nightly sync
    job that re-scores an entire project's backlog at once.
    """
    if not issues:
        raise HTTPException(status_code=400, detail="Request body must contain at least one issue.")

    rows = [issue.model_dump(by_alias=True) for issue in issues]
    df = pd.DataFrame(rows)

    scored = _score_dataframe(df)
    return [
        _build_response(issue.issue_key, scored["bottleneck_score"].iloc[i], scored["is_bottleneck"].iloc[i])
        for i, issue in enumerate(issues)
    ]
