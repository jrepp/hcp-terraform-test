# modules/security/variables.tf
# Variables for the security module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy to"
  type        = string
}

variable "service_account_name" {
  description = "Service account name to use"
  type        = string
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

variable "enable_network_policies" {
  description = "Whether to enable network policies"
  type        = bool
  default     = true
}

# Topaz configuration
variable "enable_topaz" {
  description = "Whether to deploy Topaz (OpenFGA) authorization service"
  type        = bool
  default     = true
}

variable "topaz_config" {
  description = "Topaz configuration"
  type = object({
    image_repository = string
    image_tag        = string
    replica_count    = number
    log_level        = string
    model_name       = string
    allowed_origins  = list(string)
    
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
    
    # TLS configuration
    tls_cert = string
    tls_key  = string
    
    # HPA configuration
    enable_hpa = bool
    hpa_config = object({
      min_replicas                = number
      max_replicas                = number
      target_cpu_utilization      = number
      target_memory_utilization   = number
    })
    
    # PDB configuration
    pdb_min_available = string
    
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
    image_repository = "ghcr.io/aserto-dev/topaz"
    image_tag        = "latest"
    replica_count    = 1
    log_level        = "info"
    model_name       = "basic-rbac"
    allowed_origins  = ["*"]
    
    resources = {
      requests = {
        cpu    = "200m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
    
    # Default self-signed cert (should be replaced in production)
    tls_cert = <<-EOT
-----BEGIN CERTIFICATE-----
MIICljCCAX4CCQCKw7VfDnP8QjANBgkqhkiG9w0BAQsFADANMQswCQYDVQQGEwJV
UzAeFw0yMzEwMDEwMDAwMDBaFw0yNDEwMDEwMDAwMDBaMA0xCzAJBgNVBAYTAlVT
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1234567890...
-----END CERTIFICATE-----
EOT
    
    tls_key = <<-EOT
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDXYZ...
-----END PRIVATE KEY-----
EOT
    
    enable_hpa = false
    hpa_config = {
      min_replicas                = 1
      max_replicas                = 3
      target_cpu_utilization      = 70
      target_memory_utilization   = 80
    }
    
    pdb_min_available = "1"
    
    node_selector = {}
    tolerations   = []
  }
}

variable "database_config" {
  description = "Database configuration for Topaz"
  type = object({
    host     = string
    port     = number
    database = string
    username = string
    password = string
  })
  default = {
    host     = "postgres"
    port     = 5432
    database = "topaz"
    username = "topaz"
    password = "topaz123"
  }
}
