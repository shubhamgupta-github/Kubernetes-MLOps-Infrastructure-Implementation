module "cluster" {
  source       = "./modules/cluster"
  cluster_name = var.cluster_name
}

module "minio" {
  source = "./modules/minio"

  namespace          = "minio"
  replicas           = 1
  minio_image        = "minio/minio:latest"
  image_pull_policy  = "IfNotPresent" # Use IfNotPresent to avoid unnecessary pulls
  root_user          = "admin"
  root_password      = "admin123"
  service_type       = "NodePort" # Change to LoadBalancer or ClusterIP as needed
  enable_persistence = false       # Set to true if you want persistent storage
  storage_size       = "10Gi"
  storage_class_name = "standard"

  # Ensure cluster is fully ready before deploying MinIO
  depends_on = [module.cluster]
}

# Add explicit dependency check for cluster readiness
resource "null_resource" "minio_deployment_check" {
  depends_on = [module.minio]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      export KUBECONFIG="${module.cluster.kubeconfig_path}"
      echo "Checking MinIO deployment status..."
      kubectl wait --for=condition=available deployment/minio -n minio --timeout=300s
      echo "MinIO deployment is ready!"
    EOT
  }
}