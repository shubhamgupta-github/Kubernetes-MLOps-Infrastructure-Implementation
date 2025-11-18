"""
FastAPI ML Inference Service with Prometheus Metrics
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
import pickle
import os
import logging

from prometheus_fastapi_instrumentator import Instrumentator
from prometheus_client import Gauge


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="ML Inference Service",
    description="Simple sentiment analysis API",
    version="1.0.0"
)

# ---------------------------
# PROMETHEUS METRICS
# ---------------------------

model_loaded_gauge = Gauge("model_loaded", "Whether the ML model loaded successfully")
vectorizer_loaded_gauge = Gauge("vectorizer_loaded", "Whether the vectorizer loaded successfully")

# Add Prometheus instrumentation (the REAL metrics endpoint)
Instrumentator().instrument(app).expose(app, include_in_schema=False)

# ---------------------------
# MODEL
# ---------------------------

vectorizer = None
model = None
tenant_name = os.getenv("TENANT_NAME", "unknown")


class PredictionRequest(BaseModel):
    text: str


class PredictionResponse(BaseModel):
    text: str
    prediction: str
    confidence: float
    tenant: str


def train_simple_model():
    texts = [
        "I love this product", "This is amazing", "Great experience",
        "Excellent service", "Very good quality", "Highly recommend",
        "Terrible product", "Very disappointed", "Waste of money",
        "Poor quality", "Not recommended", "Bad experience"
    ]
    labels = [1,1,1,1,1,1,0,0,0,0,0,0]

    vec = TfidfVectorizer(max_features=100)
    X = vec.fit_transform(texts)

    clf = MultinomialNB()
    clf.fit(X, labels)
    return vec, clf


@app.on_event("startup")
async def startup_event():
    global vectorizer, model

    logger.info(f"Starting ML Inference Service for tenant: {tenant_name}")

    model_dir = "/app/models"
    vec_path = os.path.join(model_dir, "vectorizer.pkl")
    model_path = os.path.join(model_dir, "model.pkl")

    if os.path.exists(vec_path) and os.path.exists(model_path):
        logger.info("Loading pre-trained model...")
        with open(vec_path, "rb") as f:
            vectorizer = pickle.load(f)
        with open(model_path, "rb") as f:
            model = pickle.load(f)
    else:
        logger.info("Training a new model...")
        vectorizer, model = train_simple_model()
        os.makedirs(model_dir, exist_ok=True)
        with open(vec_path, "wb") as f:
            pickle.dump(vectorizer, f)
        with open(model_path, "wb") as f:
            pickle.dump(model, f)

    # Update metrics AFTER model loads
    model_loaded_gauge.set(1)
    vectorizer_loaded_gauge.set(1)

    logger.info("Model loaded successfully!")


@app.get("/")
async def root():
    return {"status": "healthy", "tenant": tenant_name}


@app.get("/health")
async def health():
    if model is None or vectorizer is None:
        raise HTTPException(503, "Model not loaded")
    return {"status": "healthy"}


@app.get("/ready")
async def ready():
    if model is None or vectorizer is None:
        raise HTTPException(503, "Model not ready")
    return {"status": "ready"}


@app.post("/predict", response_model=PredictionResponse)
async def predict(request: PredictionRequest):
    if model is None or vectorizer is None:
        raise HTTPException(503, "Model not initialized")

    X = vectorizer.transform([request.text])
    prediction = model.predict(X)[0]
    probs = model.predict_proba(X)[0]
    confidence = float(max(probs))
    sentiment = "positive" if prediction == 1 else "negative"

    return PredictionResponse(
        text=request.text,
        prediction=sentiment,
        confidence=confidence,
        tenant=tenant_name
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
