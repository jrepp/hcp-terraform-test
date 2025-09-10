# environments/staging/variables.tf
# Variables specific to the staging environment

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "k8s-demo"
}

variable "domain_name" {
  description = "Base domain name for the application"
  type        = string
  default     = "staging.local.dev"
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "staging"
}

variable "cluster_type" {
  description = "Type of Kubernetes cluster"
  type        = string
  default     = "microk8s"
  
  validation {
    condition = contains([
      "microk8s", 
      "docker-desktop", 
      "kind", 
      "minikube",
      "gke", 
      "eks", 
      "aks"
    ], var.cluster_type)
    error_message = "Cluster type must be one of: microk8s, docker-desktop, kind, minikube, gke, eks, aks."
  }
}

variable "storage_class" {
  description = "Storage class to use for persistent volumes"
  type        = string
  default     = "microk8s-hostpath"
}

# Kubernetes configuration
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = ""
}

# Feature flags
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
  description = "Enable cert-manager for TLS"
  type        = bool
  default     = true
}

variable "enable_gitops" {
  description = "Enable ArgoCD for GitOps"
  type        = bool
  default     = false
}

variable "enable_topaz" {
  description = "Enable Topaz authorization service"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Enable Kubernetes network policies"
  type        = bool
  default     = true
}

variable "enable_debug" {
  description = "Enable debug mode"
  type        = bool
  default     = false
}

# Database passwords (should be managed via secrets in production)
variable "postgresql_password" {
  description = "PostgreSQL admin password"
  type        = string
  default     = "postgres123"
  sensitive   = true
}

variable "database_password" {
  description = "Application database password"
  type        = string
  default     = "apppass123"
  sensitive   = true
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  default     = "redis123"
  sensitive   = true
}

variable "clickhouse_password" {
  description = "ClickHouse password"
  type        = string
  default     = "clickhouse123"
  sensitive   = true
}

variable "minio_password" {
  description = "MinIO admin password"
  type        = string
  default     = "minio123456"
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "argocd_admin_password" {
  description = "ArgoCD admin password"
  type        = string
  default     = "argocd123"
  sensitive   = true
}

# Resource quotas for staging
variable "resource_quotas" {
  description = "Resource quotas for the staging environment"
  type = object({
    cpu_limit     = string
    memory_limit  = string
    storage_limit = string
  })
  default = {
    cpu_limit     = "2"
    memory_limit  = "4Gi"
    storage_limit = "20Gi"
  }
}

# Replica counts for staging (lower than production)
variable "replica_counts" {
  description = "Default replica counts for staging"
  type = object({
    web_apps    = number
    databases   = number
    monitoring  = number
  })
  default = {
    web_apps   = 1
    databases  = 1
    monitoring = 1
  }
}

# Backup settings
variable "backup_retention_days" {
  description = "Number of days to retain backups in staging"
  type        = number
  default     = 3
  
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 30
    error_message = "Backup retention days must be between 1 and 30 for staging."
  }
}

# Development-specific settings
variable "development_mode" {
  description = "Enable development-specific configurations"
  type        = bool
  default     = true
}

variable "auto_scaling_enabled" {
  description = "Enable auto-scaling for applications"
  type        = bool
  default     = true
}

variable "persistence_enabled" {
  description = "Enable persistent storage (disable for ephemeral staging)"
  type        = bool
  default     = true
}
