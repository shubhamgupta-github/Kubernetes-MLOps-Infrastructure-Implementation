# Delete existing cluster (ignore errors)
kind delete cluster --name mlops-kind-cluster | Out-Null

# Create a new cluster with explicit config and kubeconfig output
kind create cluster `
  --name mlops-kind-cluster `
  --config "$PSScriptRoot\kind-config.yaml" `
  --kubeconfig "$PSScriptRoot\kubeconfig"
