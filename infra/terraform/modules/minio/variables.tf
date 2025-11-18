variable "namespace" {
  description = "Kubernetes namespace for MinIO"
  type        = string
  default     = "minio"
}

variable "replicas" {
  description = "Number of MinIO replicas"
  type        = number
  default     = 1
}

variable "minio_image" {
  description = "MinIO Docker image"
  type        = string
  default     = "minio/minio:latest"
}

variable "image_pull_policy" {
  description = "Image pull policy (Always, IfNotPresent, Never)"
  type        = string
  default     = "IfNotPresent"
}

variable "root_user" {
  description = "MinIO root user"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "root_password" {
  description = "MinIO root password"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "service_type" {
  description = "Kubernetes service type (ClusterIP, NodePort, LoadBalancer)"
  type        = string
  default     = "ClusterIP"
}

variable "enable_persistence" {
  description = "Enable persistent storage for MinIO"
  type        = bool
  default     = false
}

variable "storage_size" {
  description = "Size of persistent storage"
  type        = string
  default     = "10Gi"
}

variable "storage_class_name" {
  description = "Storage class name for PVC"
  type        = string
  default     = "standard"
}

