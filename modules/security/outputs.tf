# modules/security/outputs.tf
# Outputs for the security module

output "topaz_service_name" {
  description = "Name of the Topaz service"
  value       = var.enable_topaz ? kubernetes_service.topaz[0].metadata[0].name : null
}

output "topaz_authz_port" {
  description = "Topaz authorization gRPC port"
  value       = var.enable_topaz ? 8282 : null
}

output "topaz_authz_gateway_port" {
  description = "Topaz authorization gateway port"
  value       = var.enable_topaz ? 8383 : null
}

output "topaz_directory_port" {
  description = "Topaz directory gRPC port"
  value       = var.enable_topaz ? 9292 : null
}

output "topaz_directory_gateway_port" {
  description = "Topaz directory gateway port"
  value       = var.enable_topaz ? 9393 : null
}

output "topaz_metrics_port" {
  description = "Topaz metrics port"
  value       = var.enable_topaz ? 8080 : null
}

output "topaz_deployment_name" {
  description = "Name of the Topaz deployment"
  value       = var.enable_topaz ? kubernetes_deployment.topaz[0].metadata[0].name : null
}

output "topaz_config_map_name" {
  description = "Name of the Topaz configuration ConfigMap"
  value       = var.enable_topaz ? kubernetes_config_map.topaz_config[0].metadata[0].name : null
}

output "topaz_tls_secret_name" {
  description = "Name of the Topaz TLS secret"
  value       = var.enable_topaz ? kubernetes_secret.topaz_tls[0].metadata[0].name : null
}

output "topaz_connection_info" {
  description = "Connection information for Topaz services"
  value = var.enable_topaz ? {
    authz_grpc_url      = "grpc://${kubernetes_service.topaz[0].metadata[0].name}.${var.namespace}.svc.cluster.local:8282"
    authz_gateway_url   = "http://${kubernetes_service.topaz[0].metadata[0].name}.${var.namespace}.svc.cluster.local:8383"
    directory_grpc_url  = "grpc://${kubernetes_service.topaz[0].metadata[0].name}.${var.namespace}.svc.cluster.local:9292"
    directory_gateway_url = "http://${kubernetes_service.topaz[0].metadata[0].name}.${var.namespace}.svc.cluster.local:9393"
    metrics_url         = "http://${kubernetes_service.topaz[0].metadata[0].name}.${var.namespace}.svc.cluster.local:8080/metrics"
  } : null
}

output "topaz_hpa_info" {
  description = "Information about Topaz HPA"
  value = var.enable_topaz && var.topaz_config.enable_hpa ? {
    name         = kubernetes_horizontal_pod_autoscaler_v2.topaz[0].metadata[0].name
    min_replicas = kubernetes_horizontal_pod_autoscaler_v2.topaz[0].spec[0].min_replicas
    max_replicas = kubernetes_horizontal_pod_autoscaler_v2.topaz[0].spec[0].max_replicas
  } : null
}

output "topaz_pdb_info" {
  description = "Information about Topaz Pod Disruption Budget"
  value = var.enable_topaz && var.topaz_config.replica_count > 1 ? {
    name          = kubernetes_pod_disruption_budget_v1.topaz[0].metadata[0].name
    min_available = kubernetes_pod_disruption_budget_v1.topaz[0].spec[0].min_available
  } : null
}

output "topaz_network_policy_info" {
  description = "Information about Topaz network policy"
  value = var.enable_topaz && var.enable_network_policies ? {
    name      = kubernetes_network_policy.topaz[0].metadata[0].name
    namespace = kubernetes_network_policy.topaz[0].metadata[0].namespace
  } : null
}
