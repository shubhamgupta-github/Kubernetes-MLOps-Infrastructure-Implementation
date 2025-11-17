##############################
# Tenant A Network Policies
##############################

resource "kubernetes_network_policy" "tenant_a_default_deny" {
  metadata {
    name      = "default-deny"
    namespace = "tenant-a"
  }

  spec {
    pod_selector {}     # selects ALL pods
    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy" "tenant_a_allow_internal" {
  metadata {
    name      = "allow-internal"
    namespace = "tenant-a"
  }

  spec {
    pod_selector {}     # all pods

    ingress {
      from {
        pod_selector {}   # allow traffic from pods IN SAME namespace
      }
    }

    egress {
      to {
        pod_selector {}    # allow traffic to pods IN SAME namespace
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}

##############################
# Tenant B Network Policies
##############################

resource "kubernetes_network_policy" "tenant_b_default_deny" {
  metadata {
    name      = "default-deny"
    namespace = "tenant-b"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy" "tenant_b_allow_internal" {
  metadata {
    name      = "allow-internal"
    namespace = "tenant-b"
  }

  spec {
    pod_selector {}

    ingress {
      from {
        pod_selector {}
      }
    }

    egress {
      to {
        pod_selector {}
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}
