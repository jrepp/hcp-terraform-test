# environments/production/outputs.tf
# Production environment outputs

# Environment Information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "domain_name" {
  description = "Primary domain name"
  value       = var.domain_name
}

# Kubernetes Base Infrastructure Outputs
output "namespace_name" {
  description = "Kubernetes namespace name"
  value       = module.kubernetes_base.namespace_name
}

output "service_account_name" {
  description = "Service account name"
  value       = module.kubernetes_base.service_account_name
}

output "network_policy_names" {
  description = "Network policy names"
  value       = module.kubernetes_base.network_policy_names
}

output "resource_quota_name" {
  description = "Resource quota name"
  value       = module.kubernetes_base.resource_quota_name
}

# Data Services Outputs
output "postgresql_service_name" {
  description = "PostgreSQL service name"
  value       = module.data_services.postgresql_service_name
}

output "postgresql_service_port" {
  description = "PostgreSQL service port"
  value       = module.data_services.postgresql_service_port
}

output "redis_service_name" {
  description = "Redis service name"
  value       = module.data_services.redis_service_name
}

output "redis_service_port" {
  description = "Redis service port"
  value       = module.data_services.redis_service_port
}

output "clickhouse_service_name" {
  description = "ClickHouse service name"
  value       = module.data_services.clickhouse_service_name
}

output "clickhouse_service_port" {
  description = "ClickHouse service port"
  value       = module.data_services.clickhouse_service_port
}

output "minio_service_name" {
  description = "MinIO service name"
  value       = module.data_services.minio_service_name
}

output "minio_service_port" {
  description = "MinIO service port"
  value       = module.data_services.minio_service_port
}

output "minio_console_url" {
  description = "MinIO console URL"
  value       = module.data_services.minio_console_url
}

# Observability Outputs
output "prometheus_service_name" {
  description = "Prometheus service name"
  value       = module.observability.prometheus_service_name
}

output "prometheus_service_port" {
  description = "Prometheus service port"
  value       = module.observability.prometheus_service_port
}

output "grafana_service_name" {
  description = "Grafana service name"
  value       = module.observability.grafana_service_name
}

output "grafana_service_port" {
  description = "Grafana service port"
  value       = module.observability.grafana_service_port
}

output "grafana_admin_username" {
  description = "Grafana admin username"
  value       = module.observability.grafana_admin_username
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "https://grafana.${var.domain_name}"
}

output "alertmanager_service_name" {
  description = "AlertManager service name"
  value       = module.observability.alertmanager_service_name
}

output "alertmanager_service_port" {
  description = "AlertManager service port"
  value       = module.observability.alertmanager_service_port
}

# Security Service Outputs
output "topaz_service_name" {
  description = "Topaz service name"
  value       = var.enable_topaz ? module.security.topaz_service_name : null
}

output "topaz_service_port" {
  description = "Topaz service port"
  value       = var.enable_topaz ? module.security.topaz_service_port : null
}

output "topaz_api_url" {
  description = "Topaz API URL"
  value       = var.enable_topaz ? "https://topaz.${var.domain_name}" : null
}

# Networking Outputs
output "istio_gateway_name" {
  description = "Istio gateway name"
  value       = var.enable_istio ? module.networking.istio_gateway_name : null
}

output "istio_gateway_service_name" {
  description = "Istio gateway service name"
  value       = var.enable_istio ? module.networking.istio_gateway_service_name : null
}

output "istio_gateway_service_port" {
  description = "Istio gateway service port"
  value       = var.enable_istio ? module.networking.istio_gateway_service_port : null
}

output "istio_version" {
  description = "Istio version"
  value       = var.enable_istio ? module.networking.istio_version : null
}

# Certificate Management Outputs
output "cert_manager_webhook_service_name" {
  description = "Cert-manager webhook service name"
  value       = var.enable_cert_manager ? module.cert_manager.cert_manager_webhook_service_name : null
}

output "cluster_issuer_names" {
  description = "Cluster issuer names"
  value       = var.enable_cert_manager ? module.cert_manager.cluster_issuer_names : null
}

output "app_certificate_name" {
  description = "Application certificate name"
  value       = var.enable_cert_manager && var.enable_tls ? module.cert_manager.app_certificate_name : null
}

# Application Outputs
output "nginx_service_name" {
  description = "Nginx service name"
  value       = module.nginx_app.nginx_service_name
}

output "nginx_service_port" {
  description = "Nginx service port"
  value       = module.nginx_app.nginx_service_port
}

output "nginx_deployment_name" {
  description = "Nginx deployment name"
  value       = module.nginx_app.nginx_deployment_name
}

output "nginx_hpa_name" {
  description = "Nginx HPA name"
  value       = module.nginx_app.nginx_hpa_name
}

output "nginx_url" {
  description = "Nginx application URL"
  value       = "https://${var.domain_name}"
}

# GitOps Outputs
output "argocd_server_service_name" {
  description = "ArgoCD server service name"
  value       = var.enable_gitops ? module.gitops.argocd_server_service_name : null
}

output "argocd_server_service_port" {
  description = "ArgoCD server service port"
  value       = var.enable_gitops ? module.gitops.argocd_server_service_port : null
}

output "argocd_admin_username" {
  description = "ArgoCD admin username"
  value       = var.enable_gitops ? module.gitops.argocd_admin_username : null
}

output "argocd_url" {
  description = "ArgoCD URL"
  value       = var.enable_gitops ? "https://argocd.${var.domain_name}" : null
}

# Connection Information
output "connection_info" {
  description = "Connection information for services"
  value = {
    environment = var.environment
    namespace   = module.kubernetes_base.namespace_name
    
    web_application = {
      url         = "https://${var.domain_name}"
      description = "Main web application"
    }
    
    grafana = var.enable_monitoring ? {
      url         = "https://grafana.${var.domain_name}"
      username    = module.observability.grafana_admin_username
      description = "Monitoring dashboard"
    } : null
    
    argocd = var.enable_gitops ? {
      url         = "https://argocd.${var.domain_name}"
      username    = module.gitops.argocd_admin_username
      description = "GitOps dashboard"
    } : null
    
    topaz = var.enable_topaz ? {
      url         = "https://topaz.${var.domain_name}"
      description = "Authorization service"
    } : null
    
    minio = {
      console_url = module.data_services.minio_console_url
      description = "Object storage console"
    }
  }
}

# Health Check Information
output "health_checks" {
  description = "Health check endpoints"
  value = {
    nginx = {
      readiness = "http://${module.nginx_app.nginx_service_name}.${module.kubernetes_base.namespace_name}.svc.cluster.local:${module.nginx_app.nginx_service_port}/health"
      liveness  = "http://${module.nginx_app.nginx_service_name}.${module.kubernetes_base.namespace_name}.svc.cluster.local:${module.nginx_app.nginx_service_port}/health"
    }
    
    postgresql = {
      endpoint = "${module.data_services.postgresql_service_name}.${module.kubernetes_base.namespace_name}.svc.cluster.local:${module.data_services.postgresql_service_port}"
    }
    
    redis = {
      endpoint = "${module.data_services.redis_service_name}.${module.kubernetes_base.namespace_name}.svc.cluster.local:${module.data_services.redis_service_port}"
    }
    
    clickhouse = {
      endpoint = "${module.data_services.clickhouse_service_name}.${module.kubernetes_base.namespace_name}.svc.cluster.local:${module.data_services.clickhouse_service_port}"
    }
    
    minio = {
      endpoint = "${module.data_services.minio_service_name}.${module.kubernetes_base.namespace_name}.svc.cluster.local:${module.data_services.minio_service_port}"
    }
    
    prometheus = var.enable_monitoring ? {
      endpoint = "${module.observability.prometheus_service_name}.${module.kubernetes_base.namespace_name}.svc.cluster.local:${module.observability.prometheus_service_port}"
    } : null
    
    grafana = var.enable_monitoring ? {
      endpoint = "${module.observability.grafana_service_name}.${module.kubernetes_base.namespace_name}.svc.cluster.local:${module.observability.grafana_service_port}"
    } : null
    
    topaz = var.enable_topaz ? {
      endpoint = "${module.security.topaz_service_name}.${module.kubernetes_base.namespace_name}.svc.cluster.local:${module.security.topaz_service_port}"
    } : null
    
    argocd = var.enable_gitops ? {
      endpoint = "${module.gitops.argocd_server_service_name}.${module.kubernetes_base.namespace_name}.svc.cluster.local:${module.gitops.argocd_server_service_port}"
    } : null
  }
}

# Security Information
output "security_info" {
  description = "Security configuration information"
  value = {
    network_policies_enabled = var.enable_network_policies
    tls_enabled             = var.enable_tls
    istio_mtls_enabled      = var.enable_istio
    cert_manager_enabled    = var.enable_cert_manager
    letsencrypt_enabled     = var.enable_letsencrypt
    authorization_enabled   = var.enable_topaz
    
    tls_certificates = var.enable_cert_manager && var.enable_tls ? {
      app_certificate = module.cert_manager.app_certificate_name
      cluster_issuers = module.cert_manager.cluster_issuer_names
    } : null
  }
}

# Resource Information
output "resource_info" {
  description = "Resource configuration information"
  value = {
    cluster_type     = var.cluster_type
    storage_class    = var.storage_class
    ingress_class    = var.ingress_class
    
    high_availability = {
      nginx_replicas     = 3
      istio_replicas     = var.enable_istio ? 3 : 0
      argocd_replicas    = var.enable_gitops ? 2 : 0
      postgresql_mode    = "replication"
      redis_mode         = "replication"
    }
    
    monitoring_enabled = var.enable_monitoring
    tracing_enabled    = var.enable_tracing
    gitops_enabled     = var.enable_gitops
  }
}
