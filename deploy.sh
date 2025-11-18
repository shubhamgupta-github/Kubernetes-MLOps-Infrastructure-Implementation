#!/bin/bash
# Simple deployment script

set -e

echo "🚀 Deploying ML Inference Service"
echo ""

# Step 1: Build image
echo "📦 Step 1: Building Docker image..."
cd ml-inference-service
docker build -t ml-inference-service:latest .
echo "✅ Image built!"
echo ""

# Step 2: Load into Kind
echo "📦 Step 2: Loading image into Kind cluster..."
kind load docker-image ml-inference-service:latest --name mlops-kind-cluster
echo "✅ Image loaded!"
echo ""

# Step 3: Deploy tenant-a
echo "🎯 Step 3: Deploying tenant-a..."
cd ..
kubectl apply -f k8s-manifests/tenant-a/
echo "✅ Tenant-a deployed!"
echo ""

# Step 4: Deploy tenant-b
echo "🎯 Step 4: Deploying tenant-b..."
kubectl apply -f k8s-manifests/tenant-b/
echo "✅ Tenant-b deployed!"
echo ""

# Wait for pods
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=ml-inference,tenant=tenant-a -n tenant-a --timeout=300s
kubectl wait --for=condition=ready pod -l app=ml-inference,tenant=tenant-b -n tenant-b --timeout=300s
echo "✅ All pods ready!"
echo ""

# Show status
echo "📊 Deployment Status:"
echo ""
echo "Tenant A:"
kubectl get pods -n tenant-a
echo ""
echo "Tenant B:"
kubectl get pods -n tenant-b
echo ""

echo "🎉 Deployment complete!"
echo ""
echo "To test:"
echo "  kubectl port-forward -n tenant-a svc/tenant-a-ml-inference-svc 8000:8000"
echo "  curl -X POST http://localhost:8000/predict -H 'Content-Type: application/json' -d '{\"text\": \"I love this!\"}'"

