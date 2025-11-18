#!/bin/bash
# Test ML Inference API

TENANT="${1:-tenant-a}"
NAMESPACE="${TENANT}"
SERVICE_NAME="${TENANT}-ml-inference-svc"
PORT="${2:-8000}"

echo "🧪 Testing ML Inference Service for $TENANT"
echo ""

# Port forward in background
echo "Setting up port forward..."
kubectl port-forward -n "$NAMESPACE" "svc/$SERVICE_NAME" "$PORT:8000" &
PF_PID=$!

# Wait for port forward to be ready
sleep 3

echo ""
echo "📊 Health Check:"
curl -s http://localhost:$PORT/health | jq .

echo ""
echo "🤖 Positive Sentiment Test:"
curl -s -X POST http://localhost:$PORT/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I love this product! It is amazing!"}' | jq .

echo ""
echo "😞 Negative Sentiment Test:"
curl -s -X POST http://localhost:$PORT/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "This is terrible and disappointing"}' | jq .

echo ""
echo "📈 Metrics:"
curl -s http://localhost:$PORT/metrics | jq .

# Cleanup
echo ""
echo "Cleaning up port forward..."
kill $PF_PID 2>/dev/null || true

echo "✅ Tests complete!"

