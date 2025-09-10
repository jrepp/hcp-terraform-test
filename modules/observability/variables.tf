# modules/observability/variables.tf
# Variables for the observability module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "namespace" {
  description = "Application namespace to monitor"
  type        = string
}

variable "monitoring_namespace" {
  description = "Namespace for monitoring components"
  type        = string
  default     = "monitoring"
}

variable "domain_name" {
  description = "Base domain name"
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

# Prometheus configuration
variable "enable_prometheus" {
  description = "Whether to deploy Prometheus"
  type        = bool
  default     = true
}

variable "prometheus_config" {
  description = "Prometheus configuration"
  type = object({
    retention    = string
    storage_size = string
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
  })
  default = {
    retention    = "15d"
    storage_size = "10Gi"
    resources = {
      requests = {
        cpu    = "200m"
        memory = "512Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "1Gi"
      }
    }
  }
}

# Grafana configuration
variable "enable_grafana" {
  description = "Whether to deploy Grafana"
  type        = bool
  default     = true
}

variable "grafana_config" {
  description = "Grafana configuration"
  type = object({
    admin_password = string
    storage_size   = string
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
  })
  default = {
    admin_password = "admin123"
    storage_size   = "2Gi"
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
  }
}

# AlertManager configuration
variable "enable_alertmanager" {
  description = "Whether to deploy AlertManager"
  type        = bool
  default     = true
}

variable "alertmanager_config" {
  description = "AlertManager configuration"
  type = object({
    storage_size = string
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
  })
  default = {
    storage_size = "1Gi"
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
  }
}

variable "enable_node_exporter" {
  description = "Whether to deploy Node Exporter"
  type        = bool
  default     = true
}

variable "enable_app_monitoring" {
  description = "Whether to create ServiceMonitor and alerts for applications"
  type        = bool
  default     = true
}
