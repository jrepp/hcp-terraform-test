# modules/gitops/main.tf
# GitOps module - ArgoCD for continuous deployment

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# Install ArgoCD using Helm
resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0
  
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_config.version
  namespace  = var.argocd_namespace
  
  create_namespace = true
  
  values = [yamlencode({
    global = {
      image = {
        repository = var.argocd_config.image_repository
        tag        = var.argocd_config.image_tag
      }
      
      securityContext = {
        runAsNonRoot = true
        runAsUser    = 999
        fsGroup      = 999
      }
    }
    
    # ArgoCD Server configuration
    server = {
      replicas = var.argocd_config.server_replicas
      
      resources = var.argocd_config.server_resources
      
      service = {
        type = var.argocd_config.server_service_type
        port = 80
        portName = "http"
        annotations = var.argocd_config.server_service_annotations
      }
      
      ingress = var.enable_argocd_ingress ? {
        enabled = true
        ingressClassName = var.argocd_ingress_config.ingress_class
        hostname = var.argocd_ingress_config.hostname
        tls = var.argocd_ingress_config.enable_tls
        extraTls = var.argocd_ingress_config.enable_tls ? [
          {
            hosts = [var.argocd_ingress_config.hostname]
            secretName = "${var.environment}-argocd-tls"
          }
        ] : []
        annotations = var.argocd_ingress_config.annotations
      } : {
        enabled = false
      }
      
      # Configuration
      config = {
        url = var.argocd_config.server_url
        
        # OIDC configuration if enabled
        oidc_config = var.enable_oidc ? {
          name = "OIDC"
          issuer = var.oidc_config.issuer
          clientId = var.oidc_config.client_id
          clientSecret = var.oidc_config.client_secret
          requestedScopes = var.oidc_config.requested_scopes
          requestedIDTokenClaims = var.oidc_config.requested_id_token_claims
        } : null
        
        # Repository configuration
        repositories = yamlencode(var.repository_configs)
      }
      
      # RBAC configuration
      rbacConfig = {
        "policy.default" = var.rbac_config.default_policy
        "policy.csv" = var.rbac_config.policy_csv
        "scopes" = var.rbac_config.scopes
      }
      
      # Additional command line arguments
      extraArgs = concat([
        "--insecure=${var.argocd_config.insecure}"
      ], var.argocd_config.extra_args)
      
      # Node selection
      nodeSelector = var.argocd_config.node_selector
      tolerations  = var.argocd_config.tolerations
    }
    
    # ArgoCD Repository Server
    repoServer = {
      replicas = var.argocd_config.repo_server_replicas
      resources = var.argocd_config.repo_server_resources
      
      nodeSelector = var.argocd_config.node_selector
      tolerations  = var.argocd_config.tolerations
    }
    
    # ArgoCD Application Controller
    controller = {
      replicas = var.argocd_config.controller_replicas
      resources = var.argocd_config.controller_resources
      
      # Metrics
      metrics = {
        enabled = var.enable_monitoring
        serviceMonitor = {
          enabled = var.enable_monitoring
          labels = var.common_labels
        }
      }
      
      nodeSelector = var.argocd_config.node_selector
      tolerations  = var.argocd_config.tolerations
    }
    
    # ArgoCD Dex (OIDC)
    dex = {
      enabled = var.enable_oidc
      resources = var.argocd_config.dex_resources
      
      nodeSelector = var.argocd_config.node_selector
      tolerations  = var.argocd_config.tolerations
    }
    
    # Redis (ArgoCD's cache)
    redis = {
      enabled = true
      resources = var.argocd_config.redis_resources
      
      nodeSelector = var.argocd_config.node_selector
      tolerations  = var.argocd_config.tolerations
    }
    
    # Common labels
    commonLabels = var.common_labels
    
    # Prometheus monitoring
    prometheus = {
      enabled = var.enable_monitoring
      service = {
        enabled = var.enable_monitoring
        serviceMonitor = {
          enabled = var.enable_monitoring
          labels = var.common_labels
        }
      }
    }
  })]
  
  depends_on = [var.base_module_dependency]
}

# Create ArgoCD Projects
resource "kubernetes_manifest" "argocd_projects" {
  for_each = var.enable_argocd ? var.argocd_projects : {}
  
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    
    metadata = {
      name      = each.key
      namespace = var.argocd_namespace
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "argocd-project"
      })
    }
    
    spec = {
      description = each.value.description
      
      sourceRepos = each.value.source_repos
      
      destinations = each.value.destinations
      
      clusterResourceWhitelist = each.value.cluster_resource_whitelist
      
      namespaceResourceWhitelist = each.value.namespace_resource_whitelist
      
      roles = each.value.roles
    }
  }
  
  depends_on = [helm_release.argocd]
}

# Create ArgoCD Applications
resource "kubernetes_manifest" "argocd_applications" {
  for_each = var.enable_argocd ? var.argocd_applications : {}
  
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    
    metadata = {
      name      = each.key
      namespace = var.argocd_namespace
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "argocd-application"
      })
      
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    
    spec = {
      project = each.value.project
      
      source = {
        repoURL        = each.value.source.repo_url
        path           = each.value.source.path
        targetRevision = each.value.source.target_revision
        
        dynamic "helm" {
          for_each = each.value.source.helm != null ? [each.value.source.helm] : []
          content {
            valueFiles = helm.value.value_files
            values     = helm.value.values
          }
        }
        
        dynamic "kustomize" {
          for_each = each.value.source.kustomize != null ? [each.value.source.kustomize] : []
          content {
            namePrefix = kustomize.value.name_prefix
            nameSuffix = kustomize.value.name_suffix
            images     = kustomize.value.images
          }
        }
      }
      
      destination = {
        server    = each.value.destination.server
        namespace = each.value.destination.namespace
      }
      
      syncPolicy = each.value.sync_policy
    }
  }
  
  depends_on = [kubernetes_manifest.argocd_projects]
}

# Create NetworkPolicy for ArgoCD (if enabled)
resource "kubernetes_network_policy" "argocd" {
  count = var.enable_argocd && var.enable_network_policies ? 1 : 0
  
  metadata {
    name      = "argocd-netpol"
    namespace = var.argocd_namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "argocd-network-policy"
    })
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/part-of" = "argocd"
      }
    }

    policy_types = ["Ingress", "Egress"]

    # Allow ingress to ArgoCD server
    ingress {
      from {
        namespace_selector {}
      }
      
      ports {
        port     = "8080"
        protocol = "TCP"
      }
      ports {
        port     = "8083"
        protocol = "TCP"
      }
    }

    # Allow communication within ArgoCD
    ingress {
      from {
        pod_selector {
          match_labels = {
            "app.kubernetes.io/part-of" = "argocd"
          }
        }
      }
    }

    # Allow egress to Git repositories
    egress {
      to {}
      ports {
        port     = "22"
        protocol = "TCP"
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
      ports {
        port     = "80"
        protocol = "TCP"
      }
    }
    
    # Allow egress to Kubernetes API
    egress {
      to {}
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }
    
    # Allow DNS
    egress {
      to {}
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
  
  depends_on = [helm_release.argocd]
}

# Create Secret for ArgoCD admin password
resource "kubernetes_secret" "argocd_admin_password" {
  count = var.enable_argocd && var.argocd_config.admin_password != "" ? 1 : 0
  
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.argocd_namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "argocd-secret"
    })
  }

  data = {
    password = var.argocd_config.admin_password
  }

  type = "Opaque"
  
  depends_on = [helm_release.argocd]
}
