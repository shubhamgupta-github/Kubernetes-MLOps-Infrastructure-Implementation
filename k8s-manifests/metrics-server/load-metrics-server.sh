#!/bin/bash
# Pre-load metrics-server image into Kind cluster

set -e

CLUSTER_NAME="${1:-mlops-kind-cluster}"
IMAGE="k8s.gcr.io/metrics-server/metrics-server:v0.6.4"

echo "📦 Pulling metrics-server image..."
docker pull "$IMAGE"

echo ""
echo "📤 Loading image into Kind cluster: $CLUSTER_NAME"
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"

echo ""
echo "✅ Metrics-server image loaded into Kind!"
echo ""
echo "Now deploy metrics-server:"
echo "  kubectl apply -f k8s-manifests/metrics-server/metrics-server.yaml"

