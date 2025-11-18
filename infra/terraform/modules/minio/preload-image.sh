#!/bin/bash
# Script to pre-load MinIO image into Kind cluster
# This avoids Docker Hub pull issues during deployment

set -e

CLUSTER_NAME="${1:-mlops-kind-cluster}"
IMAGE="${2:-minio/minio:latest}"

echo "Pre-loading MinIO image into Kind cluster..."
echo "Cluster: $CLUSTER_NAME"
echo "Image: $IMAGE"

# Pull image locally first
echo "Pulling image locally..."
docker pull "$IMAGE"

# Load image into Kind cluster
echo "Loading image into Kind cluster..."
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"

echo "✅ Image loaded successfully!"
echo "You can now deploy MinIO with imagePullPolicy: IfNotPresent or Never"

