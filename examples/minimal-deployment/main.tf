# examples/minimal-deployment/main.tf
# Minimal deployment example for learning and resource-constrained environments

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
}

# Configure providers
provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

# Variables
variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "minimal"
}

# Create basic Kubernetes infrastructure
module "kubernetes_base" {
  source = "../../modules/kubernetes-base"
  
  environment   = var.environment
  project_name  = "minimal-demo"
  namespace     = var.environment
  domain_name   = "minimal.local"
  cluster_type  = "microk8s"
  
  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "minimal-demo"
    "app.kubernetes.io/environment" = var.environment
  }
  
  common_annotations = {
    "terraform.io/managed" = "true"
    "example"             = "minimal-deployment"
  }
  
  enable_network_policies = false  # Disabled for simplicity
  
  # Minimal resource limits
  resource_limits = {
    cpu_requests    = "1"
    memory_requests = "2Gi"
    cpu_limits      = "2"
    memory_limits   = "4Gi"
    pvc_count      = 5
    service_count  = 10
    pod_count      = 20
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
}

# Deploy minimal data services
module "data_services" {
  source = "../../modules/data-services"
  
  environment   = var.environment
  namespace     = module.kubernetes_base.namespace_name
  storage_class = "standard"
  
  common_labels           = module.kubernetes_base.common_labels
  enable_monitoring       = false  # Disabled for minimal setup
  enable_network_policies = false
  
  base_module_dependency = module.kubernetes_base
  
  # Enable only PostgreSQL for minimal setup
  enable_postgresql = true
  enable_redis      = false
  enable_clickhouse = false
  enable_minio      = false
  
  postgresql_config = {
    postgres_password = "minimal-postgres"
    username         = "appuser"
    password         = "minimal-db"
    database         = "appdb"
    architecture     = "standalone"  # Single instance
    storage_size     = "2Gi"         # Small storage
    resources = {
      requests = {
        cpu    = "100m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
  }
}

# Deploy simple nginx application
module "nginx_app" {
  source = "../../modules/nginx-app"
  
  environment          = var.environment
  namespace            = module.kubernetes_base.namespace_name
  cluster_type         = "microk8s"
  service_account_name = module.kubernetes_base.service_account_name
  storage_class        = "standard"
  
  common_labels = module.kubernetes_base.common_labels
  
  base_module_dependency = module.kubernetes_base
  
  enable_istio_injection = false  # No service mesh for minimal setup
  enable_persistent_logs = false  # No persistent logs
  
  nginx_config = {
    image_repository = "nginx"
    image_tag        = "1.25-alpine@sha256:6a2f8b28e45c4adea04ec207a251fd4a2df03ddc930f8d33871a0b9abf4f3dbb"
    replica_count    = 1  # Single replica
    
    resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "200m"
        memory = "128Mi"
      }
    }
    
    enable_hpa = false  # No autoscaling
  }
}

# Outputs
output "connection_info" {
  description = "Connection information for minimal deployment"
  value = {
    environment = var.environment
    namespace   = module.kubernetes_base.namespace_name
    
    nginx_service = {
      name = module.nginx_app.nginx_service_name
      port = module.nginx_app.nginx_service_port
      command = "kubectl port-forward -n ${module.kubernetes_base.namespace_name} svc/${module.nginx_app.nginx_service_name} 8080:80"
      url = "http://localhost:8080"
    }
    
    postgresql = {
      service = module.data_services.postgresql_service_name
      port    = module.data_services.postgresql_service_port
      command = "kubectl exec -it -n ${module.kubernetes_base.namespace_name} deployment/postgresql -- psql -U appuser -d appdb"
    }
  }
}

output "next_steps" {
  description = "Next steps after deployment"
  value = [
    "1. Port forward to nginx: kubectl port-forward -n ${module.kubernetes_base.namespace_name} svc/${module.nginx_app.nginx_service_name} 8080:80",
    "2. Access application: http://localhost:8080",
    "3. Connect to database: kubectl exec -it -n ${module.kubernetes_base.namespace_name} deployment/postgresql -- psql -U appuser -d appdb",
    "4. View resources: kubectl get all -n ${module.kubernetes_base.namespace_name}",
    "5. Clean up: terraform destroy"
  ]
}