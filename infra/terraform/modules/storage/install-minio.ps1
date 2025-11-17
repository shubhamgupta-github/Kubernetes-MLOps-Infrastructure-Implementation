param(
    [string]$Namespace = "storage",
    [string]$ChartPath
)

if (-not $ChartPath) {
    throw "ChartPath not provided."
}

Write-Host "Using chart path: $ChartPath"

# Namespace check without -ErrorAction (Windows-safe)
$ns = kubectl get namespace $Namespace 2>$null
if (-not $ns) {
    kubectl create namespace $Namespace
}

helm upgrade --install minio $ChartPath `
    --namespace $Namespace `
    --set auth.rootUser=admin `
    --set auth.rootPassword=password123 `
    --set service.type=NodePort `
    --set service.nodePorts.api=31000
