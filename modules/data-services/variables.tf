# modules/data-services/variables.tf
# Variables for the data-services module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy to"
  type        = string
}

variable "storage_class" {
  description = "Storage class to use for persistent volumes"
  type        = string
  default     = "standard"
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_monitoring" {
  description = "Whether to enable monitoring/metrics"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Whether to enable network policies"
  type        = bool
  default     = true
}

variable "base_module_dependency" {
  description = "Dependency on the base module to ensure proper ordering"
  type        = any
  default     = null
}

# PostgreSQL configuration
variable "enable_postgresql" {
  description = "Whether to deploy PostgreSQL"
  type        = bool
  default     = true
}

variable "postgresql_config" {
  description = "PostgreSQL configuration"
  type = object({
    postgres_password = string
    username         = string
    password         = string
    database         = string
    architecture     = string
    storage_size     = string
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
    postgres_password = "postgres123"
    username         = "appuser"
    password         = "apppass123"
    database         = "appdb"
    architecture     = "standalone"
    storage_size     = "8Gi"
    resources = {
      requests = {
        cpu    = "250m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
  }
}

# Redis configuration
variable "enable_redis" {
  description = "Whether to deploy Redis"
  type        = bool
  default     = true
}

variable "redis_config" {
  description = "Redis configuration"
  type = object({
    password      = string
    architecture  = string
    replica_count = number
    storage_size  = string
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
    password      = "redis123"
    architecture  = "standalone"
    replica_count = 1
    storage_size  = "2Gi"
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

# ClickHouse configuration
variable "enable_clickhouse" {
  description = "Whether to deploy ClickHouse"
  type        = bool
  default     = true
}

variable "clickhouse_config" {
  description = "ClickHouse configuration"
  type = object({
    username     = string
    password     = string
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
    username     = "clickhouse"
    password     = "clickhouse123"
    storage_size = "10Gi"
    resources = {
      requests = {
        cpu    = "500m"
        memory = "512Mi"
      }
      limits = {
        cpu    = "1000m"
        memory = "1Gi"
      }
    }
  }
}

# MinIO configuration
variable "enable_minio" {
  description = "Whether to deploy MinIO"
  type        = bool
  default     = true
}

variable "minio_config" {
  description = "MinIO configuration"
  type = object({
    root_user        = string
    root_password    = string
    default_buckets  = list(string)
    storage_size     = string
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
    root_user       = "minioadmin"
    root_password   = "minio123456"
    default_buckets = ["app-data", "backups", "logs"]
    storage_size    = "20Gi"
    resources = {
      requests = {
        cpu    = "250m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
  }
}
