# modules/nginx-app/outputs.tf
# Outputs for the nginx-app module

output "nginx_service_name" {
  description = "Name of the nginx service"
  value       = kubernetes_service.nginx.metadata[0].name
}

output "nginx_service_port" {
  description = "Port of the nginx service"
  value       = 80
}

output "nginx_metrics_port" {
  description = "Port for nginx metrics"
  value       = 8080
}

output "nginx_deployment_name" {
  description = "Name of the nginx deployment"
  value       = kubernetes_deployment.nginx.metadata[0].name
}

output "nginx_config_map_name" {
  description = "Name of the nginx configuration ConfigMap"
  value       = kubernetes_config_map.nginx_config.metadata[0].name
}

output "nginx_pvc_name" {
  description = "Name of the nginx logs PVC (if enabled)"
  value       = var.enable_persistent_logs ? kubernetes_persistent_volume_claim.nginx_logs[0].metadata[0].name : null
}

output "nginx_hpa_name" {
  description = "Name of the nginx HPA (if enabled)"
  value       = var.nginx_config.enable_hpa ? kubernetes_horizontal_pod_autoscaler_v2.nginx[0].metadata[0].name : null
}

output "nginx_url" {
  description = "Internal URL for the nginx service"
  value       = "http://${kubernetes_service.nginx.metadata[0].name}.${var.namespace}.svc.cluster.local"
}

output "nginx_metrics_url" {
  description = "URL for nginx metrics endpoint"
  value       = "http://${kubernetes_service.nginx.metadata[0].name}.${var.namespace}.svc.cluster.local:8080/metrics"
}

output "nginx_health_endpoints" {
  description = "Health check endpoints"
  value = {
    health    = "http://${kubernetes_service.nginx.metadata[0].name}.${var.namespace}.svc.cluster.local:8080/health"
    readiness = "http://${kubernetes_service.nginx.metadata[0].name}.${var.namespace}.svc.cluster.local:8080/ready"
  }
}

output "nginx_replica_info" {
  description = "Nginx replica configuration"
  value = {
    current_replicas = var.nginx_config.replica_count
    hpa_enabled      = var.nginx_config.enable_hpa
    min_replicas     = var.nginx_config.enable_hpa ? var.nginx_config.hpa_config.min_replicas : var.nginx_config.replica_count
    max_replicas     = var.nginx_config.enable_hpa ? var.nginx_config.hpa_config.max_replicas : var.nginx_config.replica_count
  }
}
