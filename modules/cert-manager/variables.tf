# modules/cert-manager/variables.tf
# Variables for the cert-manager module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "namespace" {
  description = "Application namespace"
  type        = string
}

variable "cert_manager_namespace" {
  description = "cert-manager namespace"
  type        = string
  default     = "cert-manager"
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

# cert-manager configuration
variable "enable_cert_manager" {
  description = "Whether to deploy cert-manager"
  type        = bool
  default     = true
}

variable "cert_manager_config" {
  description = "cert-manager configuration"
  type = object({
    version   = string
    log_level = number
    
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
    
    webhook_resources = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
    
    cainjector_resources = object({
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
    version   = "v1.13.1"
    log_level = 2
    
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
    
    webhook_resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    
    cainjector_resources = {
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

# Let's Encrypt configuration
variable "enable_letsencrypt" {
  description = "Whether to create Let's Encrypt ClusterIssuers"
  type        = bool
  default     = false
}

variable "letsencrypt_config" {
  description = "Let's Encrypt configuration"
  type = object({
    email         = string
    ingress_class = string
  })
  default = {
    email         = "admin@example.com"
    ingress_class = "nginx"
  }
}

# Self-signed certificates configuration
variable "enable_selfsigned" {
  description = "Whether to create self-signed ClusterIssuer and CA"
  type        = bool
  default     = true
}

# Application certificate configuration
variable "create_app_certificate" {
  description = "Whether to create a certificate for the application"
  type        = bool
  default     = true
}

variable "app_certificate_config" {
  description = "Application certificate configuration"
  type = object({
    common_name   = string
    dns_names     = list(string)
    duration      = string
    renew_before  = string
    issuer_name   = string
  })
  default = {
    common_name  = "app.local.dev"
    dns_names    = ["app.local.dev", "*.app.local.dev"]
    duration     = "2160h"  # 90 days
    renew_before = "720h"   # 30 days
    issuer_name  = "ca-issuer"
  }
}
