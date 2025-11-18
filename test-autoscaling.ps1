# Load testing script to trigger HPA autoscaling

param(
    [string]$Tenant = "tenant-a",
    [int]$Duration = 300,  # 5 minutes default
    [int]$Concurrency = 10
)

Write-Host "🔥 Load Testing for $Tenant" -ForegroundColor Cyan
Write-Host "Duration: ${Duration}s"
Write-Host "Concurrency: $Concurrency requests/sec"
Write-Host ""

# Port forward in background
Write-Host "Setting up port forward..." -ForegroundColor Yellow
$portForwardJob = Start-Job -ScriptBlock {
    param($tenant)
    kubectl port-forward -n $tenant "svc/${tenant}-ml-inference-svc" 8000:8000
} -ArgumentList $Tenant

# Wait for port forward
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "📊 Watch HPA status in another terminal:" -ForegroundColor Cyan
Write-Host "  kubectl get hpa -n $Tenant -w"
Write-Host ""
Write-Host "📈 Watch pods scaling in another terminal:" -ForegroundColor Cyan
Write-Host "  kubectl get pods -n $Tenant -w"
Write-Host ""
Write-Host "Starting load test in 5 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Generate load
Write-Host "🚀 Generating load..." -ForegroundColor Green
$endTime = (Get-Date).AddSeconds($Duration)

while ((Get-Date) -lt $endTime) {
    for ($i = 0; $i -lt $Concurrency; $i++) {
        Start-Job -ScriptBlock {
            try {
                Invoke-RestMethod -Uri "http://localhost:8000/predict" `
                    -Method Post `
                    -ContentType "application/json" `
                    -Body '{"text": "This is a test for autoscaling!"}' `
                    -ErrorAction SilentlyContinue | Out-Null
            } catch {
                # Ignore errors
            }
        } | Out-Null
    }
    Start-Sleep -Seconds 1
    
    # Clean up completed jobs
    Get-Job -State Completed | Remove-Job
}

Write-Host ""
Write-Host "✅ Load test complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Check HPA status:" -ForegroundColor Cyan
kubectl get hpa -n $Tenant

Write-Host ""
Write-Host "Check pod count:" -ForegroundColor Cyan
kubectl get pods -n $Tenant | Select-String "ml-inference"

# Cleanup
Write-Host ""
Write-Host "Cleaning up..." -ForegroundColor Yellow
Stop-Job -Job $portForwardJob
Remove-Job -Job $portForwardJob
Get-Job | Remove-Job -Force

Write-Host ""
Write-Host "Pods will scale down after 5 minutes of low CPU usage." -ForegroundColor Yellow

