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

output "kubeconfig_path" {
  value = "${path.module}/kubeconfig"
}
