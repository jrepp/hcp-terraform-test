# environments/staging/outputs.tf
# Outputs for the staging environment

# Namespace information
output "namespace_name" {
  description = "Name of the created namespace"
  value       = module.kubernetes_base.namespace_name
}

output "service_account_name" {
  description = "Name of the service account"
  value       = module.kubernetes_base.service_account_name
}

# Data services outputs
output "database_services" {
  description = "Database service connection information"
  value = {
    postgresql = {
      service_name = module.data_services.postgresql_service_name
      port         = module.data_services.postgresql_port
      database     = module.data_services.postgresql_database
    }
    redis = {
      service_name = module.data_services.redis_service_name
      port         = module.data_services.redis_port
    }
    clickhouse = {
      service_name = module.data_services.clickhouse_service_name
      http_port    = module.data_services.clickhouse_http_port
      tcp_port     = module.data_services.clickhouse_tcp_port
    }
    minio = {
      service_name   = module.data_services.minio_service_name
      api_port       = module.data_services.minio_api_port
      console_port   = module.data_services.minio_console_port
      buckets        = module.data_services.minio_buckets
    }
  }
}

output "database_credentials_secret" {
  description = "Name of the secret containing database credentials"
  value       = module.data_services.database_credentials_secret
}

# Monitoring outputs
output "monitoring_services" {
  description = "Monitoring service information"
  value = var.enable_monitoring ? {
    prometheus = {
      service_name = module.observability.prometheus_service_name
      port         = module.observability.prometheus_port
    }
    grafana = {
      service_name = module.observability.grafana_service_name
      port         = module.observability.grafana_port
    }
    alertmanager = {
      service_name = module.observability.alertmanager_service_name
      port         = module.observability.alertmanager_port
    }
  } : {}
}

output "grafana_admin_credentials" {
  description = "Grafana admin credentials"
  value       = var.enable_monitoring ? module.observability.grafana_admin_credentials : null
  sensitive   = true
}

# Security outputs
output "security_services" {
  description = "Security service information"
  value = var.enable_topaz ? {
    topaz = {
      service_name         = module.security.topaz_service_name
      authz_port          = module.security.topaz_authz_port
      authz_gateway_port  = module.security.topaz_authz_gateway_port
      directory_port      = module.security.topaz_directory_port
      directory_gateway_port = module.security.topaz_directory_gateway_port
      metrics_port        = module.security.topaz_metrics_port
    }
  } : {}
}

# Networking outputs
output "networking_info" {
  description = "Networking and service mesh information"
  value = var.enable_istio ? {
    istio_system_namespace = module.networking.istio_system_namespace
    gateway_name          = module.networking.gateway_name
    virtual_service_name  = module.networking.virtual_service_name
    mtls_configuration    = module.networking.mtls_configuration
    gateway_hosts         = module.networking.gateway_hosts
  } : {}
}

# Certificate management outputs
output "certificate_info" {
  description = "Certificate management information"
  value = var.enable_cert_manager ? {
    cert_manager_namespace = module.cert_manager.cert_manager_namespace
    cluster_issuers       = module.cert_manager.cluster_issuers
    app_certificate_name  = module.cert_manager.app_certificate_name
    app_certificate_secret = module.cert_manager.app_certificate_secret_name
  } : {}
}

# Application outputs
output "application_services" {
  description = "Application service information"
  value = {
    nginx = {
      service_name     = module.nginx_app.nginx_service_name
      service_port     = module.nginx_app.nginx_service_port
      metrics_port     = module.nginx_app.nginx_metrics_port
      deployment_name  = module.nginx_app.nginx_deployment_name
      url             = module.nginx_app.nginx_url
      health_endpoints = module.nginx_app.nginx_health_endpoints
      replica_info    = module.nginx_app.nginx_replica_info
    }
  }
}

# GitOps outputs
output "gitops_info" {
  description = "GitOps service information"
  value = var.enable_gitops ? {
    argocd_namespace    = module.gitops.argocd_namespace
    argocd_server_url   = module.gitops.argocd_server_url
    argocd_projects     = module.gitops.argocd_projects
    argocd_applications = module.gitops.argocd_applications
    cli_info           = module.gitops.argocd_cli_info
  } : {}
}

# Quick access URLs for development
output "quick_access_urls" {
  description = "Quick access URLs for development and testing"
  value = {
    # Port forwarding commands for local access
    grafana_port_forward = var.enable_monitoring ? "kubectl port-forward -n ${module.observability.monitoring_namespace} svc/${module.observability.grafana_service_name} 3000:${module.observability.grafana_port}" : ""
    
    prometheus_port_forward = var.enable_monitoring ? "kubectl port-forward -n ${module.observability.monitoring_namespace} svc/${module.observability.prometheus_service_name} 9090:${module.observability.prometheus_port}" : ""
    
    nginx_port_forward = "kubectl port-forward -n ${module.kubernetes_base.namespace_name} svc/${module.nginx_app.nginx_service_name} 8080:${module.nginx_app.nginx_service_port}"
    
    argocd_port_forward = var.enable_gitops ? "kubectl port-forward -n ${module.gitops.argocd_namespace} svc/${module.gitops.argocd_server_service_name} 8080:${module.gitops.argocd_server_port}" : ""
    
    # Internal service URLs
    nginx_internal_url = module.nginx_app.nginx_url
    grafana_internal_url = var.enable_monitoring ? module.observability.service_urls.grafana : ""
    prometheus_internal_url = var.enable_monitoring ? module.observability.service_urls.prometheus : ""
  }
}

# Environment summary
output "environment_summary" {
  description = "Summary of the deployed staging environment"
  value = {
    environment         = var.environment
    project_name        = var.project_name
    namespace           = module.kubernetes_base.namespace_name
    cluster_type        = var.cluster_type
    domain_name         = var.domain_name
    
    enabled_features = {
      monitoring       = var.enable_monitoring
      service_mesh     = var.enable_istio
      cert_manager     = var.enable_cert_manager
      gitops          = var.enable_gitops
      authorization   = var.enable_topaz
      network_policies = var.enable_network_policies
    }
    
    deployed_services = {
      nginx        = "✅ Deployed"
      postgresql   = "✅ Deployed"
      redis        = "✅ Deployed"
      clickhouse   = "✅ Deployed"
      minio        = "✅ Deployed"
      prometheus   = var.enable_monitoring ? "✅ Deployed" : "❌ Disabled"
      grafana      = var.enable_monitoring ? "✅ Deployed" : "❌ Disabled"
      istio        = var.enable_istio ? "✅ Deployed" : "❌ Disabled"
      cert_manager = var.enable_cert_manager ? "✅ Deployed" : "❌ Disabled"
      topaz        = var.enable_topaz ? "✅ Deployed" : "❌ Disabled"
      argocd       = var.enable_gitops ? "✅ Deployed" : "❌ Disabled"
    }
    
    resource_usage = {
      namespaces = 1
      deployments = var.enable_monitoring ? 8 : 5  # Approximate count
      services = var.enable_monitoring ? 12 : 8    # Approximate count
      secrets = 2
      configmaps = 3
    }
  }
}
