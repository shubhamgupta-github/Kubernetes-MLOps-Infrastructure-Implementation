#########################
# Tenant A RBAC
#########################

resource "kubernetes_service_account" "tenant_a_sa" {
  metadata {
    name      = "tenant-a-sa"
    namespace = "tenant-a"
  }
}

resource "kubernetes_role" "tenant_a_role" {
  metadata {
    name      = "tenant-a-role"
    namespace = "tenant-a"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "watch", "create", "update", "delete"]
  }
}

resource "kubernetes_role_binding" "tenant_a_rb" {
  metadata {
    name      = "tenant-a-rb"
    namespace = "tenant-a"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.tenant_a_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tenant_a_sa.metadata[0].name
    namespace = "tenant-a"
  }
}

#########################
# Tenant B RBAC
#########################

resource "kubernetes_service_account" "tenant_b_sa" {
  metadata {
    name      = "tenant-b-sa"
    namespace = "tenant-b"
  }
}

resource "kubernetes_role" "tenant_b_role" {
  metadata {
    name      = "tenant-b-role"
    namespace = "tenant-b"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "watch", "create", "update", "delete"]
  }
}

resource "kubernetes_role_binding" "tenant_b_rb" {
  metadata {
    name      = "tenant-b-rb"
    namespace = "tenant-b"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.tenant_b_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tenant_b_sa.metadata[0].name
    namespace = "tenant-b"
  }
}
