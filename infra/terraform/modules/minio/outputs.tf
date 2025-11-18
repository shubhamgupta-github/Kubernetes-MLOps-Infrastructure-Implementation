output "namespace" {
  description = "MinIO namespace"
  value       = kubernetes_namespace.minio.metadata[0].name
}

output "service_name" {
  description = "MinIO service name"
  value       = kubernetes_service.minio.metadata[0].name
}

output "api_endpoint" {
  description = "MinIO API endpoint"
  value       = "${kubernetes_service.minio.metadata[0].name}.${kubernetes_namespace.minio.metadata[0].name}.svc.cluster.local:9000"
}

output "console_endpoint" {
  description = "MinIO Console endpoint"
  value       = "${kubernetes_service.minio.metadata[0].name}.${kubernetes_namespace.minio.metadata[0].name}.svc.cluster.local:9001"
}

