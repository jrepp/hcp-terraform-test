# modules/kubernetes-base/outputs.tf
# Outputs for the kubernetes-base module

output "namespace_name" {
  description = "Name of the created namespace"
  value       = kubernetes_namespace.app.metadata[0].name
}

output "namespace_uid" {
  description = "UID of the created namespace"
  value       = kubernetes_namespace.app.metadata[0].uid
}

output "service_account_name" {
  description = "Name of the created service account"
  value       = kubernetes_service_account.app.metadata[0].name
}

output "service_account_namespace" {
  description = "Namespace of the service account"
  value       = kubernetes_service_account.app.metadata[0].namespace
}

output "cluster_role_name" {
  description = "Name of the created cluster role"
  value       = kubernetes_cluster_role.app.metadata[0].name
}

output "config_map_name" {
  description = "Name of the application config map"
  value       = kubernetes_config_map.app_config.metadata[0].name
}

output "resource_quota_name" {
  description = "Name of the resource quota"
  value       = kubernetes_resource_quota.app.metadata[0].name
}

output "limit_range_name" {
  description = "Name of the limit range"
  value       = kubernetes_limit_range.app.metadata[0].name
}

output "network_policies" {
  description = "Information about created network policies"
  value = var.enable_network_policies ? {
    default_deny = {
      name      = kubernetes_network_policy.default_deny[0].metadata[0].name
      namespace = kubernetes_network_policy.default_deny[0].metadata[0].namespace
    }
    allow_same_namespace = {
      name      = kubernetes_network_policy.allow_same_namespace[0].metadata[0].name
      namespace = kubernetes_network_policy.allow_same_namespace[0].metadata[0].namespace
    }
  } : {}
}
