# MinIO Module
# Deploys MinIO object storage in Kubernetes

resource "kubernetes_namespace" "minio" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_deployment" "minio" {
  metadata {
    name      = "minio"
    namespace = kubernetes_namespace.minio.metadata[0].name
  }

  timeouts {
    create = "10m"
    update = "10m"
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "minio"
      }
    }

    template {
      metadata {
        labels = {
          app = "minio"
        }
      }

      spec {
        container {
          name              = "minio"
          image             = var.minio_image
          image_pull_policy = var.image_pull_policy

          args = [
            "server",
            "/data",
            "--console-address",
            ":9001"
          ]

          env {
            name  = "MINIO_ROOT_USER"
            value = var.root_user
          }

          env {
            name  = "MINIO_ROOT_PASSWORD"
            value = var.root_password
          }

          port {
            container_port = 9000
            name           = "api"
          }

          port {
            container_port = 9001
            name           = "console"
          }

          # Optional: Add volume mount for persistent storage
          dynamic "volume_mount" {
            for_each = var.enable_persistence ? [1] : []
            content {
              name       = "data"
              mount_path = "/data"
            }
          }
        }

        # Optional: Add persistent volume
        dynamic "volume" {
          for_each = var.enable_persistence ? [1] : []
          content {
            name = "data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.minio[0].metadata[0].name
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.minio]
}

# Optional: Service to expose MinIO
resource "kubernetes_service" "minio" {
  metadata {
    name      = "minio"
    namespace = kubernetes_namespace.minio.metadata[0].name
  }

  spec {
    selector = {
      app = "minio"
    }

    port {
      name        = "api"
      port        = 9000
      target_port = 9000
      protocol    = "TCP"
    }

    port {
      name        = "console"
      port        = 9001
      target_port = 9001
      protocol    = "TCP"
    }

    type = var.service_type
  }

  depends_on = [kubernetes_deployment.minio]
}

# Optional: PVC for persistent storage
resource "kubernetes_persistent_volume_claim" "minio" {
  count = var.enable_persistence ? 1 : 0

  metadata {
    name      = "minio-pvc"
    namespace = kubernetes_namespace.minio.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    
    resources {
      requests = {
        storage = var.storage_size
      }
    }

    storage_class_name = var.storage_class_name
  }

  depends_on = [kubernetes_namespace.minio]
}

