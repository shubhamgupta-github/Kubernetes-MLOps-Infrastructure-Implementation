"""
FastAPI ML Inference Service
Simple sentiment analysis model using sklearn
"""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
import pickle
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="ML Inference Service",
    description="Simple sentiment analysis API",
    version="1.0.0"
)

# Global model variables
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
    """Train a simple sentiment analysis model"""
    # Simple training data
    texts = [
        "I love this product", "This is amazing", "Great experience",
        "Excellent service", "Very good quality", "Highly recommend",
        "Terrible product", "Very disappointed", "Waste of money",
        "Poor quality", "Not recommended", "Bad experience"
    ]
    labels = [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0]  # 1=positive, 0=negative
    
    # Train vectorizer and model
    vec = TfidfVectorizer(max_features=100)
    X = vec.fit_transform(texts)
    
    clf = MultinomialNB()
    clf.fit(X, labels)
    
    return vec, clf

@app.on_event("startup")
async def startup_event():
    """Initialize model on startup"""
    global vectorizer, model
    
    logger.info(f"Starting ML Inference Service for tenant: {tenant_name}")
    
    model_path = "/app/models"
    vectorizer_path = os.path.join(model_path, "vectorizer.pkl")
    model_file_path = os.path.join(model_path, "model.pkl")
    
    # Load or train model
    if os.path.exists(vectorizer_path) and os.path.exists(model_file_path):
        logger.info("Loading pre-trained model...")
        with open(vectorizer_path, 'rb') as f:
            vectorizer = pickle.load(f)
        with open(model_file_path, 'rb') as f:
            model = pickle.load(f)
    else:
        logger.info("Training new model...")
        vectorizer, model = train_simple_model()
        
        # Save model
        os.makedirs(model_path, exist_ok=True)
        with open(vectorizer_path, 'wb') as f:
            pickle.dump(vectorizer, f)
        with open(model_file_path, 'wb') as f:
            pickle.dump(model, f)
    
    logger.info("Model loaded successfully!")

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "ML Inference Service",
        "tenant": tenant_name,
        "version": "1.0.0"
    }

@app.get("/health")
async def health():
    """Kubernetes health check"""
    if model is None or vectorizer is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    return {"status": "healthy", "tenant": tenant_name}

@app.get("/ready")
async def ready():
    """Kubernetes readiness check"""
    if model is None or vectorizer is None:
        raise HTTPException(status_code=503, detail="Model not ready")
    return {"status": "ready", "tenant": tenant_name}

@app.post("/predict", response_model=PredictionResponse)
async def predict(request: PredictionRequest):
    """
    Predict sentiment of input text
    """
    if model is None or vectorizer is None:
        raise HTTPException(status_code=503, detail="Model not initialized")
    
    try:
        # Transform input text
        X = vectorizer.transform([request.text])
        
        # Make prediction
        prediction = model.predict(X)[0]
        probabilities = model.predict_proba(X)[0]
        confidence = float(max(probabilities))
        
        sentiment = "positive" if prediction == 1 else "negative"
        
        logger.info(f"Prediction for tenant {tenant_name}: {sentiment} (confidence: {confidence:.2f})")
        
        return PredictionResponse(
            text=request.text,
            prediction=sentiment,
            confidence=confidence,
            tenant=tenant_name
        )
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

@app.get("/metrics")
async def metrics():
    """Simple metrics endpoint"""
    return {
        "tenant": tenant_name,
        "model_loaded": model is not None,
        "vectorizer_loaded": vectorizer is not None
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

