# ML Inference Service

FastAPI-based sentiment analysis service using scikit-learn.

## Features

- 🚀 FastAPI REST API
- 🤖 Simple sentiment analysis (positive/negative)
- 🏥 Health check endpoints
- 📊 Metrics endpoint
- 🔄 Automatic model training on startup
- 🎯 Tenant-aware deployment

## API Endpoints

### `GET /`
Health check and service info

### `GET /health`
Kubernetes liveness probe

### `GET /ready`
Kubernetes readiness probe

### `POST /predict`
Make sentiment prediction

**Request:**
```json
{
  "text": "I love this product!"
}
```

**Response:**
```json
{
  "text": "I love this product!",
  "prediction": "positive",
  "confidence": 0.85,
  "tenant": "tenant-a"
}
```

### `GET /metrics`
Service metrics

## Build Docker Image

```bash
cd ml-inference-service
docker build -t ml-inference-service:latest .
```

## Run Locally

```bash
docker run -p 8000:8000 -e TENANT_NAME=local ml-inference-service:latest
```

## Test

```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "This is amazing!"}'
```

## Load into Kind

```bash
docker build -t ml-inference-service:latest .
kind load docker-image ml-inference-service:latest --name mlops-kind-cluster
```

