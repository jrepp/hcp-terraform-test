# modules/networking/outputs.tf
# Outputs for the networking module

output "istio_system_namespace" {
  description = "Istio system namespace"
  value       = var.istio_system_namespace
}

output "istio_base_release_info" {
  description = "Istio base Helm release information"
  value = var.enable_istio ? {
    name      = helm_release.istio_base[0].name
    chart     = helm_release.istio_base[0].chart
    version   = helm_release.istio_base[0].version
    namespace = helm_release.istio_base[0].namespace
    status    = helm_release.istio_base[0].status
  } : null
}

output "istiod_release_info" {
  description = "Istiod Helm release information"
  value = var.enable_istio ? {
    name      = helm_release.istiod[0].name
    chart     = helm_release.istiod[0].chart
    version   = helm_release.istiod[0].version
    namespace = helm_release.istiod[0].namespace
    status    = helm_release.istiod[0].status
  } : null
}

output "istio_gateway_release_info" {
  description = "Istio gateway Helm release information"
  value = var.enable_istio && var.enable_istio_gateway ? {
    name      = helm_release.istio_gateway[0].name
    chart     = helm_release.istio_gateway[0].chart
    version   = helm_release.istio_gateway[0].version
    namespace = helm_release.istio_gateway[0].namespace
    status    = helm_release.istio_gateway[0].status
  } : null
}

output "gateway_name" {
  description = "Name of the Istio Gateway"
  value       = var.enable_istio && var.enable_istio_gateway ? "${var.environment}-gateway" : null
}

output "virtual_service_name" {
  description = "Name of the Virtual Service"
  value       = var.enable_istio && var.enable_istio_gateway ? "${var.environment}-app-vs" : null
}

output "destination_rule_name" {
  description = "Name of the Destination Rule"
  value       = var.enable_istio ? "${var.environment}-app-dr" : null
}

output "peer_authentication_name" {
  description = "Name of the PeerAuthentication"
  value       = var.enable_istio && var.istio_config.enable_mtls ? "${var.environment}-default" : null
}

output "authorization_policy_name" {
  description = "Name of the AuthorizationPolicy"
  value       = var.enable_istio && var.enable_authorization ? "${var.environment}-authz" : null
}

output "external_service_entries" {
  description = "Names of created ServiceEntry resources"
  value       = var.enable_istio ? keys(var.external_services) : []
}

output "telemetry_config_name" {
  description = "Name of the Telemetry configuration"
  value       = var.enable_istio && var.enable_monitoring ? "${var.environment}-telemetry" : null
}

output "istio_injection_enabled" {
  description = "Whether Istio injection is enabled for the namespace"
  value       = var.enable_istio
}

output "mtls_configuration" {
  description = "mTLS configuration details"
  value = var.enable_istio && var.istio_config.enable_mtls ? {
    enabled = true
    mode    = var.istio_config.mtls_mode
  } : {
    enabled = false
    mode    = null
  }
}

output "gateway_hosts" {
  description = "Configured gateway hosts"
  value       = var.enable_istio && var.enable_istio_gateway ? var.gateway_config.hosts : []
}

output "service_mesh_info" {
  description = "Service mesh configuration information"
  value = var.enable_istio ? {
    mesh_id      = var.istio_config.mesh_id
    network_name = var.istio_config.network_name
    version      = var.istio_config.version
    mtls_enabled = var.istio_config.enable_mtls
    mtls_mode    = var.istio_config.mtls_mode
    tracing_enabled = var.enable_tracing
    authorization_enabled = var.enable_authorization
  } : null
}
