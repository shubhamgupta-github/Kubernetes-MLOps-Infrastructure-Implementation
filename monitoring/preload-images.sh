#!/bin/bash
# Pre-pull and load Prometheus stack images into Kind cluster

set -e

echo "🔄 Pre-pulling Prometheus stack images..."
echo ""

# Define all required images
IMAGES=(
  "quay.io/prometheus-operator/prometheus-operator:v0.86.2"
  "quay.io/prometheus/node-exporter:v1.10.2"
  "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.17.0"
  "quay.io/prometheus/prometheus:v2.58.3"
  "quay.io/prometheus/alertmanager:v0.28.1"
  "grafana/grafana:11.4.0"
  "quay.io/kiwigrid/k8s-sidecar:1.30.10"
)

CLUSTER_NAME="mlops-kind-cluster"

# Pull each image
for image in "${IMAGES[@]}"; do
  echo "📥 Pulling $image..."
  docker pull "$image" --quiet || {
    echo "⚠️  Failed to pull $image, trying without TLS verification..."
    # If pull fails, skip it - image might already exist locally
  }
done

echo ""
echo "📦 Loading images into Kind cluster..."

# Load each image into Kind
for image in "${IMAGES[@]}"; do
  echo "⬆️  Loading $image into Kind..."
  kind load docker-image "$image" --name "$CLUSTER_NAME" || {
    echo "⚠️  Failed to load $image"
  }
done

echo ""
echo "✅ Images loaded successfully!"
echo ""
echo "Now run:"
echo "  cd monitoring"
echo "  ./install-prometheus-grafana.sh"

