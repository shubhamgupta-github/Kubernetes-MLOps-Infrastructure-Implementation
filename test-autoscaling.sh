#!/bin/bash
# Load testing script to trigger HPA autoscaling

TENANT="${1:-tenant-a}"
DURATION="${2:-300}"  # 5 minutes default
CONCURRENCY="${3:-10}"

echo "🔥 Load Testing for $TENANT"
echo "Duration: ${DURATION}s"
echo "Concurrency: $CONCURRENCY requests/sec"
echo ""

# Port forward in background
echo "Setting up port forward..."
kubectl port-forward -n "$TENANT" "svc/${TENANT}-ml-inference-svc" 8000:8000 &
PF_PID=$!

# Wait for port forward
sleep 3

echo ""
echo "📊 Watch HPA status in another terminal:"
echo "  kubectl get hpa -n $TENANT -w"
echo ""
echo "📈 Watch pods scaling in another terminal:"
echo "  kubectl get pods -n $TENANT -w"
echo ""
echo "Starting load test in 5 seconds..."
sleep 5

# Generate load
echo "🚀 Generating load..."
END=$((SECONDS + DURATION))

while [ $SECONDS -lt $END ]; do
    for i in $(seq 1 $CONCURRENCY); do
        curl -s -X POST http://localhost:8000/predict \
          -H "Content-Type: application/json" \
          -d '{"text": "This is a test for autoscaling!"}' > /dev/null &
    done
    sleep 1
done

echo ""
echo "✅ Load test complete!"
echo ""
echo "Check HPA status:"
kubectl get hpa -n "$TENANT"

echo ""
echo "Check pod count:"
kubectl get pods -n "$TENANT" | grep ml-inference

# Cleanup
kill $PF_PID 2>/dev/null || true

echo ""
echo "Pods will scale down after 5 minutes of low CPU usage."

