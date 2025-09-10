# shared/variables.tf
# Global variables used across all environments

variable "project_name" {
  description = "Name of the project - used for resource naming and tagging"
  type        = string
  default     = "k8s-demo"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must only contain lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (staging, production, etc.)"
  type        = string
  
  validation {
    condition     = contains(["staging", "production", "development"], var.environment)
    error_message = "Environment must be one of: staging, production, development."
  }
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace to deploy resources into"
  type        = string
  default     = "default"
}

variable "domain_name" {
  description = "Base domain name for the application"
  type        = string
  default     = "local.dev"
}

variable "enable_monitoring" {
  description = "Whether to enable Prometheus monitoring stack"
  type        = bool
  default     = true
}

variable "enable_security" {
  description = "Whether to enable security features (Topaz, network policies)"
  type        = bool
  default     = true
}

variable "enable_service_mesh" {
  description = "Whether to enable Istio service mesh"
  type        = bool
  default     = true
}

variable "enable_gitops" {
  description = "Whether to enable ArgoCD for GitOps"
  type        = bool
  default     = false
}

variable "enable_cert_manager" {
  description = "Whether to enable cert-manager for TLS certificate management"
  type        = bool
  default     = true
}

variable "cluster_type" {
  description = "Type of Kubernetes cluster (microk8s, docker-desktop, gke, eks, aks)"
  type        = string
  default     = "microk8s"
  
  validation {
    condition = contains([
      "microk8s", 
      "docker-desktop", 
      "gke", 
      "eks", 
      "aks", 
      "kind",
      "minikube"
    ], var.cluster_type)
    error_message = "Cluster type must be one of: microk8s, docker-desktop, gke, eks, aks, kind, minikube."
  }
}

variable "resource_quotas" {
  description = "Resource quotas for the environment"
  type = object({
    cpu_limit    = string
    memory_limit = string
    storage_limit = string
  })
  default = {
    cpu_limit    = "4"
    memory_limit = "8Gi"
    storage_limit = "50Gi"
  }
}

variable "replica_counts" {
  description = "Default replica counts for different component types"
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

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention days must be between 1 and 365."
  }
}

variable "tls_config" {
  description = "TLS configuration settings"
  type = object({
    issuer_type = string  # letsencrypt-staging, letsencrypt-prod, selfsigned
    email       = string
  })
  default = {
    issuer_type = "selfsigned"
    email       = "admin@local.dev"
  }
}

# Network configuration
variable "network_config" {
  description = "Network configuration for the cluster"
  type = object({
    pod_cidr     = string
    service_cidr = string
    enable_network_policies = bool
  })
  default = {
    pod_cidr     = "10.1.0.0/16"
    service_cidr = "10.96.0.0/12"
    enable_network_policies = true
  }
}
