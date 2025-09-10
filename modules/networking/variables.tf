# modules/networking/variables.tf
# Variables for the networking module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "namespace" {
  description = "Application namespace"
  type        = string
}

variable "istio_system_namespace" {
  description = "Istio system namespace"
  type        = string
  default     = "istio-system"
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

# Istio configuration
variable "enable_istio" {
  description = "Whether to deploy Istio service mesh"
  type        = bool
  default     = true
}

variable "istio_config" {
  description = "Istio configuration"
  type = object({
    version      = string
    mesh_id      = string
    network_name = string
    hub          = string
    tag          = string
    enable_mtls  = bool
    mtls_mode    = string
    pilot_resources = object({
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
    version      = "1.19.0"
    mesh_id      = "mesh1"
    network_name = "network1"
    hub          = "docker.io/istio"
    tag          = "1.19.0"
    enable_mtls  = true
    mtls_mode    = "STRICT"
    pilot_resources = {
      requests = {
        cpu    = "200m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
  }
}

# Gateway configuration
variable "enable_istio_gateway" {
  description = "Whether to deploy Istio ingress gateway"
  type        = bool
  default     = true
}

variable "enable_tls" {
  description = "Whether to enable TLS on the gateway"
  type        = bool
  default     = false
}

variable "gateway_config" {
  description = "Gateway configuration"
  type = object({
    service_type        = string
    service_annotations = map(string)
    replica_count       = number
    hosts              = list(string)
    
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
    
    enable_hpa = bool
    hpa_config = object({
      min_replicas            = number
      max_replicas            = number
      target_cpu_utilization  = number
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
    service_type        = "LoadBalancer"
    service_annotations = {}
    replica_count       = 1
    hosts              = ["*"]
    
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
    
    enable_hpa = false
    hpa_config = {
      min_replicas           = 1
      max_replicas           = 3
      target_cpu_utilization = 70
    }
    
    node_selector = {}
    tolerations   = []
  }
}

# Authorization configuration
variable "enable_authorization" {
  description = "Whether to enable Istio authorization policies"
  type        = bool
  default     = true
}

# External services configuration
variable "external_services" {
  description = "External services to configure with ServiceEntry"
  type = map(object({
    hosts      = list(string)
    ports      = list(object({
      number   = number
      name     = string
      protocol = string
    }))
    location   = string
    resolution = string
  }))
  default = {
    httpbin = {
      hosts = ["httpbin.org"]
      ports = [
        {
          number   = 80
          name     = "http"
          protocol = "HTTP"
        },
        {
          number   = 443
          name     = "https"
          protocol = "HTTPS"
        }
      ]
      location   = "MESH_EXTERNAL"
      resolution = "DNS"
    }
  }
}

# Tracing configuration
variable "enable_tracing" {
  description = "Whether to enable distributed tracing"
  type        = bool
  default     = false
}

variable "tracing_config" {
  description = "Tracing configuration"
  type = object({
    sampling_rate = number
  })
  default = {
    sampling_rate = 1.0
  }
}
