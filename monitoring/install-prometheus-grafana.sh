#!/bin/bash
# Install Prometheus and Grafana using kube-prometheus-stack

set -e

echo "📊 Installing Prometheus + Grafana Monitoring Stack"
echo ""

# Add Prometheus community Helm repo
echo "Adding Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
echo "Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack
echo ""
echo "Installing kube-prometheus-stack (this may take 2-3 minutes)..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=30080 \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=30090 \
  --set prometheusOperator.admissionWebhooks.enabled=false \
  --set prometheusOperator.tls.enabled=false \
  --wait \
  --timeout=10m

echo ""
echo "✅ Prometheus + Grafana installed successfully!"
echo ""
echo "📍 Access URLs:"
echo "  Grafana:    http://localhost:30080"
echo "  Prometheus: http://localhost:30090"
echo ""
echo "🔐 Grafana Credentials:"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "Next steps:"
echo "  1. kubectl apply -f monitoring/servicemonitor.yaml"
echo "  2. kubectl apply -f monitoring/prometheusrule.yaml"
echo "  3. Import dashboard from monitoring/dashboard.json"

