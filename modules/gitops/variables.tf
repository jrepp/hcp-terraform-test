# modules/gitops/variables.tf
# Variables for the gitops module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "namespace" {
  description = "Application namespace"
  type        = string
}

variable "argocd_namespace" {
  description = "ArgoCD namespace"
  type        = string
  default     = "argocd"
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "base_module_dependency" {
  description = "Dependency on the base module"
  type        = any
  default     = null
}

variable "enable_monitoring" {
  description = "Whether monitoring is enabled"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Whether to enable network policies"
  type        = bool
  default     = true
}

# ArgoCD configuration
variable "enable_argocd" {
  description = "Whether to deploy ArgoCD"
  type        = bool
  default     = false
}

variable "argocd_config" {
  description = "ArgoCD configuration"
  type = object({
    version          = string
    image_repository = string
    image_tag        = string
    admin_password   = string
    server_url       = string
    insecure         = bool
    extra_args       = list(string)
    
    server_replicas           = number
    repo_server_replicas      = number
    controller_replicas       = number
    
    server_service_type        = string
    server_service_annotations = map(string)
    
    server_resources = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
    
    repo_server_resources = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
    
    controller_resources = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
    
    dex_resources = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
    
    redis_resources = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
    
    node_selector = map(string)
    tolerations = list(object({
      key      = string
      operator = string
      value    = string
      effect   = string
    }))
  })
  default = {
    version          = "5.46.7"
    image_repository = "quay.io/argoproj/argocd"
    image_tag        = "v2.8.4"
    admin_password   = ""
    server_url       = "http://localhost:8080"
    insecure         = true
    extra_args       = []
    
    server_replicas      = 1
    repo_server_replicas = 1
    controller_replicas  = 1
    
    server_service_type        = "ClusterIP"
    server_service_annotations = {}
    
    server_resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "200m"
        memory = "256Mi"
      }
    }
    
    repo_server_resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "200m"
        memory = "256Mi"
      }
    }
    
    controller_resources = {
      requests = {
        cpu    = "200m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
    
    dex_resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    
    redis_resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    
    node_selector = {}
    tolerations   = []
  }
}

# ArgoCD Ingress configuration
variable "enable_argocd_ingress" {
  description = "Whether to create ingress for ArgoCD"
  type        = bool
  default     = false
}

variable "argocd_ingress_config" {
  description = "ArgoCD ingress configuration"
  type = object({
    hostname      = string
    ingress_class = string
    enable_tls    = bool
    annotations   = map(string)
  })
  default = {
    hostname      = "argocd.local.dev"
    ingress_class = "nginx"
    enable_tls    = false
    annotations   = {}
  }
}

# OIDC configuration
variable "enable_oidc" {
  description = "Whether to enable OIDC authentication"
  type        = bool
  default     = false
}

variable "oidc_config" {
  description = "OIDC configuration"
  type = object({
    issuer                      = string
    client_id                   = string
    client_secret               = string
    requested_scopes            = list(string)
    requested_id_token_claims   = map(string)
  })
  default = {
    issuer                    = ""
    client_id                 = ""
    client_secret             = ""
    requested_scopes          = ["openid", "profile", "email", "groups"]
    requested_id_token_claims = {"groups" = {"essential": true}}
  }
}

# Repository configurations
variable "repository_configs" {
  description = "Git repository configurations"
  type = list(object({
    url      = string
    username = string
    password = string
    type     = string
  }))
  default = []
}

# RBAC configuration
variable "rbac_config" {
  description = "RBAC configuration"
  type = object({
    default_policy = string
    policy_csv     = string
    scopes         = string
  })
  default = {
    default_policy = "role:readonly"
    policy_csv     = "p, role:admin, applications, *, */*, allow\np, role:admin, clusters, *, *, allow\np, role:admin, repositories, *, *, allow\ng, argocd-admins, role:admin"
    scopes         = "[groups]"
  }
}

# ArgoCD Projects configuration
variable "argocd_projects" {
  description = "ArgoCD projects to create"
  type = map(object({
    description = string
    source_repos = list(string)
    destinations = list(object({
      namespace = string
      server    = string
    }))
    cluster_resource_whitelist = list(object({
      group = string
      kind  = string
    }))
    namespace_resource_whitelist = list(object({
      group = string
      kind  = string
    }))
    roles = list(object({
      name        = string
      description = string
      policies    = list(string)
      groups      = list(string)
    }))
  }))
  default = {
    default = {
      description  = "Default project"
      source_repos = ["*"]
      destinations = [
        {
          namespace = "*"
          server    = "https://kubernetes.default.svc"
        }
      ]
      cluster_resource_whitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
      namespace_resource_whitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
      roles = []
    }
  }
}

# ArgoCD Applications configuration
variable "argocd_applications" {
  description = "ArgoCD applications to create"
  type = map(object({
    project = string
    source = object({
      repo_url        = string
      path           = string
      target_revision = string
      helm = object({
        value_files = list(string)
        values      = string
      })
      kustomize = object({
        name_prefix = string
        name_suffix = string
        images      = list(string)
      })
    })
    destination = object({
      server    = string
      namespace = string
    })
    sync_policy = object({
      automated = object({
        prune    = bool
        selfHeal = bool
      })
      syncOptions = list(string)
    })
  }))
  default = {}
}
