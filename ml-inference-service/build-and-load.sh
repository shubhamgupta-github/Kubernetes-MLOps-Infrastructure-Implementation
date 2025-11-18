#!/bin/bash
# Build and load ML Inference Service image into Kind cluster

set -e

CLUSTER_NAME="${1:-mlops-kind-cluster}"
IMAGE_NAME="ml-inference-service:latest"

echo "🏗️  Building ML Inference Service Docker image..."
docker build -t "$IMAGE_NAME" .

echo "✅ Image built successfully!"

echo "📦 Loading image into Kind cluster: $CLUSTER_NAME"
kind load docker-image "$IMAGE_NAME" --name "$CLUSTER_NAME"

echo "✅ Image loaded into Kind cluster!"
echo ""
echo "You can now deploy with Terraform:"
echo "  cd ../infra/terraform"
echo "  terraform init"
echo "  terraform apply"

