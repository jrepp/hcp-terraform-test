# modules/nginx-app/variables.tf
# Variables for the nginx-app module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy to"
  type        = string
}

variable "cluster_type" {
  description = "Type of Kubernetes cluster"
  type        = string
  default     = "microk8s"
}

variable "service_account_name" {
  description = "Service account name to use"
  type        = string
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "standard"
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

variable "enable_istio_injection" {
  description = "Whether to enable Istio sidecar injection"
  type        = bool
  default     = true
}

variable "enable_persistent_logs" {
  description = "Whether to use persistent storage for nginx logs"
  type        = bool
  default     = false
}

variable "log_storage_size" {
  description = "Size of persistent storage for logs"
  type        = string
  default     = "1Gi"
}

variable "nginx_config" {
  description = "Nginx configuration"
  type = object({
    image_repository = string
    image_tag        = string
    replica_count    = number
    
    resources = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
    
    # HPA configuration
    enable_hpa = bool
    hpa_config = object({
      min_replicas                = number
      max_replicas                = number
      target_cpu_utilization      = number
      target_memory_utilization   = number
    })
    
    # Node selection
    node_selector = map(string)
    tolerations = list(object({
      key      = string
      operator = string
      value    = string
      effect   = string
    }))
  })
  default = {
    image_repository = "nginx"
    image_tag        = "1.25-alpine"
    replica_count    = 2
    
    resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "200m"
        memory = "256Mi"
      }
    }
    
    enable_hpa = true
    hpa_config = {
      min_replicas                = 2
      max_replicas                = 5
      target_cpu_utilization      = 70
      target_memory_utilization   = 80
    }
    
    node_selector = {}
    tolerations   = []
  }
}
