terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}

provider "kubernetes" {
  config_path = module.cluster.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = module.cluster.kubeconfig_path
  }
}

