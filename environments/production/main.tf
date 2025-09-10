# environments/production/main.tf
# Production environment configuration

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
  
  # Backend configuration for remote state (recommended for production)
  # backend "remote" {
  #   organization = "your-org"
  #   workspaces {
  #     name = "production"
  #   }
  # }
}

# Load shared configuration
locals {
  shared_locals = {
    common_tags = {
      Project     = "terraform-k8s-demo"
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "hcp-terraform-test"
      CreatedBy   = "terraform"
    }
    
    common_labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = var.project_name
      "app.kubernetes.io/environment" = var.environment
    }
    
    common_annotations = {
      "terraform.io/managed"   = "true"
      "environment"           = var.environment
      "project"              = var.project_name
    }
  }
}

# Configure Kubernetes provider
provider "kubernetes" {
  config_path = var.kubeconfig_path
  config_context = var.kube_context
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
    config_context = var.kube_context
  }
  
  # Production settings
  debug = false
}

# Create the base Kubernetes infrastructure
module "kubernetes_base" {
  source = "../../modules/kubernetes-base"
  
  environment   = var.environment
  project_name  = var.project_name
  namespace     = var.kubernetes_namespace
  domain_name   = var.domain_name
  cluster_type  = var.cluster_type
  
  common_labels      = local.shared_locals.common_labels
  common_annotations = local.shared_locals.common_annotations
  
  enable_network_policies = var.enable_network_policies
  
  # Production resource limits (higher than staging)
  resource_limits = {
    cpu_requests    = "4"
    memory_requests = "8Gi"
    cpu_limits      = "8"
    memory_limits   = "16Gi"
    pvc_count      = 20
    service_count  = 25
    pod_count      = 100
  }
  
  default_resources = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
  
  log_level    = "warn"  # Reduced logging for production
  enable_debug = false
}

# Deploy data services with production configurations
module "data_services" {
  source = "../../modules/data-services"
  
  environment   = var.environment
  namespace     = module.kubernetes_base.namespace_name
  storage_class = var.storage_class
  
  common_labels           = local.shared_locals.common_labels
  enable_monitoring       = var.enable_monitoring
  enable_network_policies = var.enable_network_policies
  
  base_module_dependency = module.kubernetes_base
  
  # Enable all data services
  enable_postgresql = true
  enable_redis      = true
  enable_clickhouse = true
  enable_minio      = true
  
  # Production-grade configurations
  postgresql_config = {
    postgres_password = var.postgresql_password
    username         = "appuser"
    password         = var.database_password
    database         = "appdb"
    architecture     = "replication"  # High availability
    storage_size     = "50Gi"         # Larger storage
    resources = {
      requests = {
        cpu    = "500m"
        memory = "1Gi"
      }
      limits = {
        cpu    = "2000m"
        memory = "2Gi"
      }
    }
  }
  
  redis_config = {
    password      = var.redis_password
    architecture  = "replication"  # High availability
    replica_count = 3
    storage_size  = "10Gi"
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
  }
  
  clickhouse_config = {
    username     = "clickhouse"
    password     = var.clickhouse_password
    storage_size = "100Gi"  # Large storage for analytics
    resources = {
      requests = {
        cpu    = "1000m"
        memory = "2Gi"
      }
      limits = {
        cpu    = "2000m"
        memory = "4Gi"
      }
    }
  }
  
  minio_config = {
    root_user       = "minioadmin"
    root_password   = var.minio_password
    default_buckets = ["prod-data", "prod-backups", "prod-logs", "prod-archives"]
    storage_size    = "200Gi"  # Large storage for production
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

# Deploy observability stack with production settings
module "observability" {
  source = "../../modules/observability"
  
  environment   = var.environment
  namespace     = module.kubernetes_base.namespace_name
  domain_name   = var.domain_name
  storage_class = var.storage_class
  
  common_labels = local.shared_locals.common_labels
  
  base_module_dependency = module.kubernetes_base
  
  enable_prometheus     = var.enable_monitoring
  enable_grafana        = var.enable_monitoring
  enable_alertmanager   = var.enable_monitoring
  enable_node_exporter  = var.enable_monitoring
  enable_app_monitoring = var.enable_monitoring
  
  # Production monitoring configurations
  prometheus_config = {
    retention    = "30d"  # Longer retention for production
    storage_size = "50Gi" # Larger storage
    resources = {
      requests = {
        cpu    = "500m"
        memory = "2Gi"
      }
      limits = {
        cpu    = "2000m"
        memory = "4Gi"
      }
    }
  }
  
  grafana_config = {
    admin_password = var.grafana_admin_password
    storage_size   = "5Gi"
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
  }
  
  alertmanager_config = {
    storage_size = "5Gi"
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

# Deploy security services with production hardening
module "security" {
  source = "../../modules/security"
  
  environment          = var.environment
  namespace            = module.kubernetes_base.namespace_name
  service_account_name = module.kubernetes_base.service_account_name
  
  common_labels           = local.shared_locals.common_labels
  enable_network_policies = var.enable_network_policies
  
  base_module_dependency = module.kubernetes_base
  
  enable_topaz = var.enable_topaz
  
  topaz_config = {
    image_repository = "ghcr.io/aserto-dev/topaz"
    image_tag        = "latest"
    replica_count    = 3  # High availability
    log_level        = "warn"  # Reduced logging
    model_name       = "rbac-model"
    allowed_origins  = ["https://${var.domain_name}"]  # Strict CORS
    
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
    
    # Production certificates (should be managed externally)
    tls_cert = var.topaz_tls_cert
    tls_key  = var.topaz_tls_key
    
    enable_hpa = true
    hpa_config = {
      min_replicas                = 3
      max_replicas                = 10
      target_cpu_utilization      = 60
      target_memory_utilization   = 70
    }
    
    pdb_min_available = "2"  # Ensure availability during updates
    node_selector     = var.node_selector
    tolerations       = var.tolerations
  }
  
  database_config = {
    host     = module.data_services.postgresql_service_name
    port     = 5432
    database = "topaz"
    username = "appuser"
    password = var.database_password
  }
}

# Deploy networking with production-grade service mesh
module "networking" {
  source = "../../modules/networking"
  
  environment = var.environment
  namespace   = module.kubernetes_base.namespace_name
  
  common_labels      = local.shared_locals.common_labels
  enable_monitoring  = var.enable_monitoring
  
  base_module_dependency = module.kubernetes_base
  
  enable_istio         = var.enable_istio
  enable_istio_gateway = var.enable_istio
  enable_tls           = var.enable_tls
  enable_authorization = var.enable_istio
  enable_tracing       = var.enable_tracing
  
  istio_config = {
    version      = "1.19.0"
    mesh_id      = "prod-mesh"
    network_name = "prod-network"
    hub          = "docker.io/istio"
    tag          = "1.19.0"
    enable_mtls  = true
    mtls_mode    = "STRICT"  # Strict mTLS for production
    pilot_resources = {
      requests = {
        cpu    = "200m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "1000m"
        memory = "1Gi"
      }
    }
  }
  
  gateway_config = {
    service_type        = "LoadBalancer"
    service_annotations = var.ingress_annotations
    replica_count       = 3  # High availability
    hosts              = [var.domain_name, "*.${var.domain_name}"]
    
    resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
    
    enable_hpa = true
    hpa_config = {
      min_replicas           = 3
      max_replicas           = 10
      target_cpu_utilization = 60
    }
    
    node_selector = var.node_selector
    tolerations   = var.tolerations
  }
  
  external_services = var.external_services
  
  tracing_config = {
    sampling_rate = 0.1  # Lower sampling rate for production
  }
}

# Deploy cert-manager with production certificates
module "cert_manager" {
  source = "../../modules/cert-manager"
  
  environment = var.environment
  namespace   = module.kubernetes_base.namespace_name
  
  common_labels           = local.shared_locals.common_labels
  enable_monitoring       = var.enable_monitoring
  enable_network_policies = var.enable_network_policies
  
  base_module_dependency = module.kubernetes_base
  
  enable_cert_manager = var.enable_cert_manager
  enable_letsencrypt  = var.enable_letsencrypt
  enable_selfsigned   = false  # No self-signed in production
  
  cert_manager_config = {
    version   = "v1.13.1"
    log_level = 1  # Reduced logging for production
    
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
    
    node_selector = var.node_selector
    tolerations   = var.tolerations
  }
  
  letsencrypt_config = {
    email         = var.letsencrypt_email
    ingress_class = var.ingress_class
  }
  
  create_app_certificate = var.enable_tls
  app_certificate_config = {
    common_name  = var.domain_name
    dns_names    = [var.domain_name, "*.${var.domain_name}"]
    duration     = "2160h"  # 90 days
    renew_before = "720h"   # 30 days
    issuer_name  = var.enable_letsencrypt ? "letsencrypt-prod" : "ca-issuer"
  }
}

# Deploy production nginx application
module "nginx_app" {
  source = "../../modules/nginx-app"
  
  environment          = var.environment
  namespace            = module.kubernetes_base.namespace_name
  cluster_type         = var.cluster_type
  service_account_name = module.kubernetes_base.service_account_name
  storage_class        = var.storage_class
  
  common_labels = local.shared_locals.common_labels
  
  base_module_dependency = module.kubernetes_base
  
  enable_istio_injection  = var.enable_istio
  enable_persistent_logs  = true  # Enable persistent logs for production
  log_storage_size       = "10Gi"
  
  nginx_config = {
    image_repository = "nginx"
    image_tag        = "1.25-alpine"
    replica_count    = 3  # High availability
    
    resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "300m"
        memory = "256Mi"
      }
    }
    
    enable_hpa = true
    hpa_config = {
      min_replicas                = 3
      max_replicas                = 20
      target_cpu_utilization      = 60
      target_memory_utilization   = 70
    }
    
    node_selector = var.node_selector
    tolerations   = var.tolerations
  }
}

# Deploy GitOps for production
module "gitops" {
  source = "../../modules/gitops"
  
  environment = var.environment
  namespace   = module.kubernetes_base.namespace_name
  
  common_labels           = local.shared_locals.common_labels
  enable_monitoring       = var.enable_monitoring
  enable_network_policies = var.enable_network_policies
  
  base_module_dependency = module.kubernetes_base
  
  enable_argocd         = var.enable_gitops
  enable_argocd_ingress = var.enable_gitops && var.enable_tls
  enable_oidc           = var.enable_oidc
  
  argocd_config = {
    version          = "5.46.7"
    image_repository = "quay.io/argoproj/argocd"
    image_tag        = "v2.8.4"
    admin_password   = var.argocd_admin_password
    server_url       = "https://argocd.${var.domain_name}"
    insecure         = false  # Secure for production
    extra_args       = []
    
    # High availability configuration
    server_replicas      = 2
    repo_server_replicas = 2
    controller_replicas  = 1
    
    server_service_type        = "ClusterIP"
    server_service_annotations = {}
    
    server_resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "300m"
        memory = "256Mi"
      }
    }
    
    repo_server_resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "300m"
        memory = "256Mi"
      }
    }
    
    controller_resources = {
      requests = {
        cpu    = "200m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "1000m"
        memory = "1Gi"
      }
    }
    
    dex_resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    
    redis_resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    
    node_selector = var.node_selector
    tolerations   = var.tolerations
  }
  
  argocd_ingress_config = {
    hostname      = "argocd.${var.domain_name}"
    ingress_class = var.ingress_class
    enable_tls    = var.enable_tls
    annotations   = var.ingress_annotations
  }
  
  oidc_config = var.oidc_config
  
  repository_configs = var.repository_configs
  
  argocd_projects = var.argocd_projects
  
  argocd_applications = var.argocd_applications
}
