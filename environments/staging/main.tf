# environments/staging/main.tf
# Staging environment configuration

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
  
  # Backend configuration for remote state
  # Uncomment and configure for production use
  # backend "remote" {
  #   organization = "your-org"
  #   workspaces {
  #     name = "staging"
  #   }
  # }
}

# Load shared configuration
locals {
  shared_locals = {
    # Include shared locals from the shared directory
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
  
  # For microk8s, you might need to set the config context
  config_context = var.kube_context
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
    config_context = var.kube_context
  }
  
  # Debug settings for development
  debug = var.enable_debug
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
  
  resource_limits = {
    cpu_requests    = "1"
    memory_requests = "2Gi"
    cpu_limits      = "2"
    memory_limits   = "4Gi"
    pvc_count      = 10
    service_count  = 15
    pod_count      = 30
  }
  
  default_resources = {
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }
  
  log_level    = "info"
  enable_debug = var.enable_debug
}

# Deploy data services (PostgreSQL, Redis, ClickHouse, MinIO)
module "data_services" {
  source = "../../modules/data-services"
  
  environment   = var.environment
  namespace     = module.kubernetes_base.namespace_name
  storage_class = var.storage_class
  
  common_labels           = local.shared_locals.common_labels
  enable_monitoring       = var.enable_monitoring
  enable_network_policies = var.enable_network_policies
  
  base_module_dependency = module.kubernetes_base
  
  # Enable all data services for staging
  enable_postgresql = true
  enable_redis      = true
  enable_clickhouse = true
  enable_minio      = true
  
  # Configure with staging-appropriate resources
  postgresql_config = {
    postgres_password = var.postgresql_password
    username         = "appuser"
    password         = var.database_password
    database         = "appdb"
    architecture     = "standalone"
    storage_size     = "5Gi"
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
  
  redis_config = {
    password      = var.redis_password
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
  
  clickhouse_config = {
    username     = "clickhouse"
    password     = var.clickhouse_password
    storage_size = "8Gi"
    resources = {
      requests = {
        cpu    = "300m"
        memory = "512Mi"
      }
      limits = {
        cpu    = "800m"
        memory = "1Gi"
      }
    }
  }
  
  minio_config = {
    root_user       = "minioadmin"
    root_password   = var.minio_password
    default_buckets = ["staging-data", "staging-backups", "staging-logs"]
    storage_size    = "10Gi"
    resources = {
      requests = {
        cpu    = "200m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "400m"
        memory = "512Mi"
      }
    }
  }
}

# Deploy observability stack (Prometheus, Grafana, AlertManager)
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
  
  # Staging-appropriate configurations
  prometheus_config = {
    retention    = "7d"
    storage_size = "5Gi"
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
  
  grafana_config = {
    admin_password = var.grafana_admin_password
    storage_size   = "1Gi"
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
  
  alertmanager_config = {
    storage_size = "1Gi"
    resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  }
}

# Deploy security services (Topaz authorization)
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
    replica_count    = 1
    log_level        = "info"
    model_name       = "basic-rbac"
    allowed_origins  = ["http://localhost:3000", "https://${var.domain_name}"]
    
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
    
    # Self-signed certificates for staging
    tls_cert = file("${path.module}/certs/tls.crt")
    tls_key  = file("${path.module}/certs/tls.key")
    
    enable_hpa = false
    hpa_config = {
      min_replicas                = 1
      max_replicas                = 2
      target_cpu_utilization      = 70
      target_memory_utilization   = 80
    }
    
    pdb_min_available = "1"
    node_selector     = {}
    tolerations       = []
  }
  
  database_config = {
    host     = module.data_services.postgresql_service_name
    port     = 5432
    database = "topaz"
    username = "appuser"
    password = var.database_password
  }
}

# Deploy networking (Istio service mesh)
module "networking" {
  source = "../../modules/networking"
  
  environment = var.environment
  namespace   = module.kubernetes_base.namespace_name
  
  common_labels      = local.shared_locals.common_labels
  enable_monitoring  = var.enable_monitoring
  
  base_module_dependency = module.kubernetes_base
  
  enable_istio         = var.enable_istio
  enable_istio_gateway = var.enable_istio
  enable_tls           = false  # Disable TLS for staging simplicity
  enable_authorization = var.enable_istio
  enable_tracing       = false  # Disable tracing for staging
  
  istio_config = {
    version      = "1.19.0"
    mesh_id      = "staging-mesh"
    network_name = "staging-network"
    hub          = "docker.io/istio"
    tag          = "1.19.0"
    enable_mtls  = true
    mtls_mode    = "PERMISSIVE"  # Use permissive mode for staging
    pilot_resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "300m"
        memory = "256Mi"
      }
    }
  }
  
  gateway_config = {
    service_type        = "LoadBalancer"
    service_annotations = {}
    replica_count       = 1
    hosts              = ["*"]
    
    resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    
    enable_hpa = false
    hpa_config = {
      min_replicas           = 1
      max_replicas           = 2
      target_cpu_utilization = 70
    }
    
    node_selector = {}
    tolerations   = []
  }
  
  external_services = {
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

# Deploy cert-manager for TLS management
module "cert_manager" {
  source = "../../modules/cert-manager"
  
  environment = var.environment
  namespace   = module.kubernetes_base.namespace_name
  
  common_labels           = local.shared_locals.common_labels
  enable_monitoring       = var.enable_monitoring
  enable_network_policies = var.enable_network_policies
  
  base_module_dependency = module.kubernetes_base
  
  enable_cert_manager = var.enable_cert_manager
  enable_letsencrypt  = false  # Use self-signed for staging
  enable_selfsigned   = true
  
  cert_manager_config = {
    version   = "v1.13.1"
    log_level = 2
    
    resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    
    webhook_resources = {
      requests = {
        cpu    = "25m"
        memory = "32Mi"
      }
      limits = {
        cpu    = "50m"
        memory = "64Mi"
      }
    }
    
    cainjector_resources = {
      requests = {
        cpu    = "25m"
        memory = "32Mi"
      }
      limits = {
        cpu    = "50m"
        memory = "64Mi"
      }
    }
    
    node_selector = {}
    tolerations   = []
  }
  
  create_app_certificate = true
  app_certificate_config = {
    common_name  = "staging.${var.domain_name}"
    dns_names    = ["staging.${var.domain_name}", "*.staging.${var.domain_name}"]
    duration     = "2160h"  # 90 days
    renew_before = "720h"   # 30 days
    issuer_name  = "ca-issuer"
  }
}

# Deploy sample nginx application
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
  enable_persistent_logs  = false  # Disable for staging simplicity
  log_storage_size       = "1Gi"
  
  nginx_config = {
    image_repository = "nginx"
    image_tag        = "1.25-alpine"
    replica_count    = 2
    
    resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    
    enable_hpa = true
    hpa_config = {
      min_replicas                = 2
      max_replicas                = 4
      target_cpu_utilization      = 70
      target_memory_utilization   = 80
    }
    
    node_selector = {}
    tolerations   = []
  }
}

# Deploy GitOps (ArgoCD) - optional for staging
module "gitops" {
  source = "../../modules/gitops"
  
  environment = var.environment
  namespace   = module.kubernetes_base.namespace_name
  
  common_labels           = local.shared_locals.common_labels
  enable_monitoring       = var.enable_monitoring
  enable_network_policies = var.enable_network_policies
  
  base_module_dependency = module.kubernetes_base
  
  enable_argocd         = var.enable_gitops
  enable_argocd_ingress = false
  enable_oidc           = false
  
  argocd_config = {
    version          = "5.46.7"
    image_repository = "quay.io/argoproj/argocd"
    image_tag        = "v2.8.4"
    admin_password   = var.argocd_admin_password
    server_url       = "http://localhost:8080"
    insecure         = true
    extra_args       = []
    
    server_replicas      = 1
    repo_server_replicas = 1
    controller_replicas  = 1
    
    server_service_type        = "ClusterIP"
    server_service_annotations = {}
    
    server_resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    
    repo_server_resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    
    controller_resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "200m"
        memory = "256Mi"
      }
    }
    
    dex_resources = {
      requests = {
        cpu    = "25m"
        memory = "32Mi"
      }
      limits = {
        cpu    = "50m"
        memory = "64Mi"
      }
    }
    
    redis_resources = {
      requests = {
        cpu    = "25m"
        memory = "32Mi"
      }
      limits = {
        cpu    = "50m"
        memory = "64Mi"
      }
    }
    
    node_selector = {}
    tolerations   = []
  }
  
  repository_configs = []
  
  argocd_projects = {
    staging = {
      description  = "Staging project"
      source_repos = ["https://github.com/your-org/app-configs"]
      destinations = [
        {
          namespace = module.kubernetes_base.namespace_name
          server    = "https://kubernetes.default.svc"
        }
      ]
      cluster_resource_whitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
      namespace_resource_whitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
      roles = []
    }
  }
  
  argocd_applications = {}
}
