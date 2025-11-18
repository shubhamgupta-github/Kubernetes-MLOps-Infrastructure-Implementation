variable "cluster_name" {
  type    = string
  default = "mlops-kind-cluster"
}

resource "null_resource" "create_kind_cluster" {
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "powershell.exe -ExecutionPolicy Bypass -File ${path.module}/create_cluster.ps1"
  }
}

# Wait for cluster to be fully ready
resource "null_resource" "wait_for_cluster" {
  depends_on = [null_resource.create_kind_cluster]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      export KUBECONFIG="${path.module}/kubeconfig"
      
      echo "Waiting for nodes to be ready..."
      kubectl wait --for=condition=ready nodes --all --timeout=300s
      
      echo "Waiting for system pods to be ready..."
      kubectl wait --for=condition=ready pods --all -n kube-system --timeout=300s
      
      echo "Waiting for CoreDNS to be ready..."
      kubectl wait --for=condition=ready pods -l k8s-app=kube-dns -n kube-system --timeout=300s
      
      # Give extra time for Docker registry certificates to be ready
      echo "Waiting 30 seconds for registry certificates..."
      sleep 30
      
      echo "Cluster is ready!"
    EOT
  }
}

output "kubeconfig_path" {
  value      = "${path.module}/kubeconfig"
  depends_on = [null_resource.wait_for_cluster]
}

output "cluster_ready" {
  value      = true
  depends_on = [null_resource.wait_for_cluster]
}
