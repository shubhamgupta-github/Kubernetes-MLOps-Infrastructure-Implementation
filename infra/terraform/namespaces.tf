resource "kubernetes_namespace" "tenant_a" {
  metadata {
    name = "tenant-a"
  }
}

resource "kubernetes_namespace" "tenant_b" {
  metadata {
    name = "tenant-b"
  }
}
