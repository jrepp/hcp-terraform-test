# environments/production/variables.tf
# Production environment variables

# Core Configuration
variable "environment" {
  description = "Environment name (must be 'production' for this environment)"
  type        = string
  default     = "production"
  
  validation {
    condition     = var.environment == "production"
    error_message = "Environment must be 'production' for the production environment."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraform-k8s-demo"
}

variable "domain_name" {
  description = "Primary domain name for the application"
  type        = string
  default     = "prod.example.com"
}

# Kubernetes Configuration
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = null
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace to deploy resources into"
  type        = string
  default     = "production"
}

variable "cluster_type" {
  description = "Type of Kubernetes cluster"
  type        = string
  default     = "production"
  
  validation {
    condition = contains([
      "minikube", 
      "kind", 
      "microk8s", 
      "docker-desktop", 
      "k3s", 
      "gke", 
      "eks", 
      "aks",
      "production"
    ], var.cluster_type)
    error_message = "Cluster type must be one of: minikube, kind, microk8s, docker-desktop, k3s, gke, eks, aks, production."
  }
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "standard"
}

# Feature Flags
variable "enable_monitoring" {
  description = "Enable Prometheus monitoring stack"
  type        = bool
  default     = true
}

variable "enable_istio" {
  description = "Enable Istio service mesh"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "Enable cert-manager for TLS certificates"
  type        = bool
  default     = true
}

variable "enable_letsencrypt" {
  description = "Enable Let's Encrypt for automatic TLS certificates"
  type        = bool
  default     = true
}

variable "enable_gitops" {
  description = "Enable ArgoCD for GitOps"
  type        = bool
  default     = true
}

variable "enable_topaz" {
  description = "Enable Topaz.sh (OpenFGA) authorization service"
  type        = bool
  default     = true
}

variable "enable_tls" {
  description = "Enable TLS/HTTPS across services"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Enable Kubernetes network policies for security"
  type        = bool
  default     = true
}

variable "enable_tracing" {
  description = "Enable distributed tracing with Jaeger"
  type        = bool
  default     = true
}

variable "enable_oidc" {
  description = "Enable OIDC authentication for ArgoCD"
  type        = bool
  default     = false
}

# Database Configuration
variable "postgresql_password" {
  description = "PostgreSQL root password"
  type        = string
  default     = "changeme-production-postgres"
  sensitive   = true
}

variable "database_password" {
  description = "Application database password"
  type        = string
  default     = "changeme-production-db"
  sensitive   = true
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  default     = "changeme-production-redis"
  sensitive   = true
}

variable "clickhouse_password" {
  description = "ClickHouse password"
  type        = string
  default     = "changeme-production-clickhouse"
  sensitive   = true
}

variable "minio_password" {
  description = "MinIO root password"
  type        = string
  default     = "changeme-production-minio"
  sensitive   = true
}

# Monitoring Configuration
variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "changeme-production-grafana"
  sensitive   = true
}

# GitOps Configuration
variable "argocd_admin_password" {
  description = "ArgoCD admin password"
  type        = string
  default     = "changeme-production-argocd"
  sensitive   = true
}

# TLS Configuration
variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
  default     = "admin@example.com"
}

variable "topaz_tls_cert" {
  description = "TLS certificate for Topaz service (base64 encoded)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "topaz_tls_key" {
  description = "TLS private key for Topaz service (base64 encoded)"
  type        = string
  default     = ""
  sensitive   = true
}

# Network Configuration
variable "ingress_class" {
  description = "Ingress class name"
  type        = string
  default     = "istio"
}

variable "ingress_annotations" {
  description = "Annotations for ingress resources"
  type        = map(string)
  default = {
    "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    "kubernetes.io/tls-acme"         = "true"
  }
}

# Scheduling Configuration
variable "node_selector" {
  description = "Node selector for production workloads"
  type        = map(string)
  default = {
    "node-role.kubernetes.io/worker" = "true"
  }
}

variable "tolerations" {
  description = "Tolerations for production workloads"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}

# External Services Configuration
variable "external_services" {
  description = "External services configuration for Istio"
  type = map(object({
    host = string
    port = number
  }))
  default = {}
}

# OIDC Configuration
variable "oidc_config" {
  description = "OIDC configuration for ArgoCD"
  type = object({
    issuer_url                   = string
    client_id                    = string
    client_secret                = string
    requested_scopes             = list(string)
    requested_id_token_claims    = map(any)
    logout_url                   = string
  })
  default = {
    issuer_url                = ""
    client_id                 = ""
    client_secret             = ""
    requested_scopes          = ["openid", "profile", "email", "groups"]
    requested_id_token_claims = {}
    logout_url                = ""
  }
  sensitive = true
}

# Repository Configuration
variable "repository_configs" {
  description = "Git repository configurations for ArgoCD"
  type = list(object({
    name               = string
    url                = string
    type               = string
    username           = string
    password           = string
    ssh_private_key    = string
    insecure           = bool
    enable_lfs         = bool
    enable_oci         = bool
  }))
  default = []
  sensitive = true
}

# ArgoCD Projects Configuration
variable "argocd_projects" {
  description = "ArgoCD projects configuration"
  type = list(object({
    name        = string
    description = string
    source_repos = list(string)
    destinations = list(object({
      name      = string
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
  default = [
    {
      name        = "production-apps"
      description = "Production applications project"
      source_repos = ["https://github.com/your-org/production-apps"]
      destinations = [
        {
          name      = "in-cluster"
          namespace = "production"
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
      roles = [
        {
          name        = "admin"
          description = "Production admin role"
          policies = [
            "p, proj:production-apps:admin, applications, *, production-apps/*, allow",
            "p, proj:production-apps:admin, repositories, *, *, allow",
            "p, proj:production-apps:admin, certificates, *, *, allow"
          ]
          groups = ["production-admins"]
        },
        {
          name        = "viewer"
          description = "Production viewer role"
          policies = [
            "p, proj:production-apps:viewer, applications, get, production-apps/*, allow",
            "p, proj:production-apps:viewer, applications, action/*, production-apps/*, deny"
          ]
          groups = ["production-viewers"]
        }
      ]
    }
  ]
}

# ArgoCD Applications Configuration
variable "argocd_applications" {
  description = "ArgoCD applications configuration"
  type = list(object({
    name         = string
    project      = string
    namespace    = string
    source_repo  = string
    source_path  = string
    source_branch = string
    auto_sync_policy = object({
      automated = object({
        prune       = bool
        self_heal   = bool
        allow_empty = bool
      })
      sync_options = list(string)
      retry = object({
        limit = number
        backoff = object({
          duration     = string
          factor       = number
          max_duration = string
        })
      })
    })
    ignore_differences = list(object({
      group               = string
      kind                = string
      name                = string
      namespace           = string
      json_pointers       = list(string)
      managed_fields_managers = list(string)
    }))
  }))
  default = []
}
