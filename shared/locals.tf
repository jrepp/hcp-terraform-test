# shared/locals.tf
# Common local values used across all environments

locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = "terraform-k8s-demo"
    ManagedBy   = "terraform"
    Repository  = "hcp-terraform-test"
    CreatedBy   = "terraform"
  }

  # Common labels for Kubernetes resources
  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "k8s-demo"
  }

  # Resource naming conventions
  naming = {
    # Standard naming pattern: {environment}-{component}-{resource-type}
    # Example: staging-nginx-service, prod-postgres-statefulset
    separator = "-"
  }

  # Common annotations
  common_annotations = {
    "terraform.io/managed" = "true"
    "docs.link"           = "https://github.com/your-org/hcp-terraform-test"
  }

  # Standard ports used across the application
  ports = {
    http          = 80
    https         = 443
    postgres      = 5432
    redis         = 6379
    clickhouse    = 8123
    minio         = 9000
    minio_console = 9001
    prometheus    = 9090
    grafana       = 3000
    argocd_server = 8080
    argocd_grpc   = 8443
    topaz_authz   = 8282
    topaz_directory = 9292
  }

  # Standard resource requirements by component type
  resource_defaults = {
    small = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "200m"
        memory = "256Mi"
      }
    }
    medium = {
      requests = {
        cpu    = "200m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
    large = {
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

  # Common storage classes and sizes
  storage = {
    classes = {
      fast   = "ssd"           # For databases requiring high IOPS
      standard = "standard"    # For general purpose storage
      backup = "cold"         # For backup and archival
    }
    sizes = {
      small  = "1Gi"
      medium = "5Gi"
      large  = "20Gi"
      xlarge = "100Gi"
    }
  }

  # Security contexts
  security_contexts = {
    # Non-root security context for most applications
    nonroot = {
      run_as_non_root = true
      run_as_user     = 65534  # nobody user
      run_as_group    = 65534  # nobody group
      fs_group        = 65534
      read_only_root_filesystem = true
    }
    
    # For applications that need specific user IDs
    postgres = {
      run_as_user  = 999
      run_as_group = 999
      fs_group     = 999
    }
  }
}
