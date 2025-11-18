# Install Prometheus and Grafana using kube-prometheus-stack

Write-Host "📊 Installing Prometheus + Grafana Monitoring Stack" -ForegroundColor Cyan
Write-Host ""

# Add Prometheus community Helm repo
Write-Host "Adding Helm repository..." -ForegroundColor Yellow
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
Write-Host "Creating monitoring namespace..." -ForegroundColor Yellow
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack
Write-Host ""
Write-Host "Installing kube-prometheus-stack (this may take 2-3 minutes)..." -ForegroundColor Yellow
helm install prometheus prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false `
  --set grafana.adminPassword=admin `
  --set grafana.service.type=NodePort `
  --set grafana.service.nodePort=30080 `
  --set prometheus.service.type=NodePort `
  --set prometheus.service.nodePort=30090 `
  --set prometheusOperator.admissionWebhooks.enabled=false `
  --set prometheusOperator.tls.enabled=false `
  --wait `
  --timeout=10m

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Installation failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Prometheus + Grafana installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Access URLs:" -ForegroundColor Cyan
Write-Host "  Grafana:    http://localhost:30080"
Write-Host "  Prometheus: http://localhost:30090"
Write-Host ""
Write-Host "🔐 Grafana Credentials:" -ForegroundColor Cyan
Write-Host "  Username: admin"
Write-Host "  Password: admin"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. kubectl apply -f monitoring/servicemonitor.yaml"
Write-Host "  2. kubectl apply -f monitoring/prometheusrule.yaml"
Write-Host "  3. Import dashboard from monitoring/dashboard.json"

