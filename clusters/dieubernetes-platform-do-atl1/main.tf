terraform {
  required_version = ">= 1.10"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "digitalocean" {}

provider "kubernetes" {
  host                   = module.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
  token                  = module.cluster.cluster_token
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
    token                  = module.cluster.cluster_token
  }
}

module "cluster" {
  source = "../../modules/digitalocean/doks-cluster"

  name                      = "dieubernetes-platform-do-atl1"
  region                    = "atl1"
  node_size                 = "s-2vcpu-8gb-amd"
  min_nodes                 = 1
  max_nodes                 = 1
  kubernetes_version_prefix = "1.36"
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [yamlencode({
    configs = {
      secret = {
        argocdServerAdminPassword = var.argocd_admin_password_bcrypt
      }
      params = {
        "server.insecure" = true
      }
    }
    server = {
      service = { type = "ClusterIP" }
    }
    applicationSet = { enabled = true }
  })]

  depends_on = [kubernetes_namespace.argocd]
}

resource "helm_release" "argocd_root" {
  name       = "argocd-root"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "1.6.1"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [yamlencode({
    applications = [{
      name      = "root"
      namespace = "argocd"
      project   = "default"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = "HEAD"
        path           = "argocd/apps"
        directory      = { recurse = true }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated   = { prune = true, selfHeal = true }
        syncOptions = ["CreateNamespace=true"]
      }
    }]
  })]

  depends_on = [helm_release.argocd]
}

# Register the platform cluster with ArgoCD's clusters generator.
# Labels it as tier:platform so ApplicationSets target it correctly.
# No CLI step needed — this replaces `dieuctl argocd register` for platform clusters.
resource "kubernetes_secret" "argocd_cluster" {
  metadata {
    name      = "platform-do-atl1"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
      "purpose"                        = "platform"
    }
  }

  data = {
    name   = "platform-do-atl1"
    server = "https://kubernetes.default.svc"
    config = jsonencode({ tlsClientConfig = { insecure = false } })
  }

  depends_on = [helm_release.argocd]
}
