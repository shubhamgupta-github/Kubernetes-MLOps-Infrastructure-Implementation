output "kubeconfig_path" {
  value = module.cluster.kubeconfig_path
}

output "minio_namespace" {
  description = "MinIO namespace"
  value       = module.minio.namespace
}

output "minio_api_endpoint" {
  description = "MinIO API endpoint (internal cluster address)"
  value       = module.minio.api_endpoint
}

output "minio_console_endpoint" {
  description = "MinIO Console endpoint (internal cluster address)"
  value       = module.minio.console_endpoint
}
