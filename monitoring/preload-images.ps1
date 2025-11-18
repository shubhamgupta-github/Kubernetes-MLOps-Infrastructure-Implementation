# Pre-pull and load Prometheus stack images into Kind cluster

Write-Host "🔄 Pre-pulling Prometheus stack images..." -ForegroundColor Cyan
Write-Host ""

# Define all required images
$images = @(
    "quay.io/prometheus-operator/prometheus-operator:v0.86.2",
    "quay.io/prometheus/node-exporter:v1.10.2",
    "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.17.0",
    "quay.io/prometheus/prometheus:v2.58.3",
    "quay.io/prometheus/alertmanager:v0.28.1",
    "grafana/grafana:11.4.0",
    "quay.io/kiwigrid/k8s-sidecar:1.30.10"
)

$clusterName = "mlops-kind-cluster"

# Pull each image
foreach ($image in $images) {
    Write-Host "📥 Pulling $image..." -ForegroundColor Yellow
    docker pull $image 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Failed to pull $image, might already exist locally" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "📦 Loading images into Kind cluster..." -ForegroundColor Cyan

# Load each image into Kind
foreach ($image in $images) {
    Write-Host "⬆️  Loading $image into Kind..." -ForegroundColor Yellow
    kind load docker-image $image --name $clusterName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Failed to load $image" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "✅ Images loaded successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Now run:" -ForegroundColor Cyan
Write-Host "  cd monitoring"
Write-Host "  .\install-prometheus-grafana.ps1"

