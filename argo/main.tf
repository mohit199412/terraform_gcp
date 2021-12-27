terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.0.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.0"
    }
  }
}

data "terraform_remote_state" "gke" {
  backend = "remote"

  config = {
    organization = "wabbit-dev"
    workspaces = {
      name = "wabbit-rk5-gke"
    }
  }
}

# resource "local_file" "kubeconfig" {
#   content  = data.terraform_remote_state.gke.outputs.kubeconfig_raw
#   filename = "~/.kube/config"
# }

provider "helm" {
  kubernetes {
    host  = data.terraform_remote_state.gke.outputs.kubernetes_endpoint
    token = data.terraform_remote_state.gke.outputs.client_token
    cluster_ca_certificate = data.terraform_remote_state.gke.outputs.ca_certificate
  }
}

resource helm_release argocd-install {
  name       = "argocd-apps"
  repository = "https://kusznerr.github.io/wabbit-rk5-gke-argo-apps"
  chart      = "argo-cd"
  version    = "1.0.4"
}

resource helm_release root-app {
    depends_on = [
      helm_release.argocd-install,
    ]
  name       = "root-app"
  repository = "https://kusznerr.github.io/wabbit-rk5-gke-argo-apps"
  chart      = "root-app"
}