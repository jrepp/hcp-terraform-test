# modules/kubernetes-base/variables.tf
# Variables for the kubernetes-base module

variable "environment" {
  description = "Environment name (staging, production, etc.)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to create and use"
  type        = string
}

variable "domain_name" {
  description = "Base domain name for the application"
  type        = string
}

variable "cluster_type" {
  description = "Type of Kubernetes cluster"
  type        = string
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "common_annotations" {
  description = "Common annotations to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_network_policies" {
  description = "Whether to create network policies for traffic isolation"
  type        = bool
  default     = true
}

variable "resource_limits" {
  description = "Resource limits for the namespace"
  type = object({
    cpu_requests    = string
    memory_requests = string
    cpu_limits      = string
    memory_limits   = string
    pvc_count      = number
    service_count  = number
    pod_count      = number
  })
  default = {
    cpu_requests    = "2"
    memory_requests = "4Gi"
    cpu_limits      = "4"
    memory_limits   = "8Gi"
    pvc_count      = 10
    service_count  = 20
    pod_count      = 50
  }
}

variable "default_resources" {
  description = "Default resource requests and limits for containers"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }
}

variable "log_level" {
  description = "Default log level for applications"
  type        = string
  default     = "info"
  
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: debug, info, warn, error."
  }
}

variable "enable_debug" {
  description = "Whether to enable debug mode for applications"
  type        = string
  default     = "false"
}
