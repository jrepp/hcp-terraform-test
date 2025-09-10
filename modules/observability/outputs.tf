# modules/observability/outputs.tf
# Outputs for the observability module

output "prometheus_service_name" {
  description = "Name of the Prometheus service"
  value       = var.enable_prometheus ? "${var.environment}-prometheus-kube-prometheus-prometheus" : null
}

output "prometheus_port" {
  description = "Prometheus service port"
  value       = var.enable_prometheus ? 9090 : null
}

output "grafana_service_name" {
  description = "Name of the Grafana service"
  value       = var.enable_grafana ? "${var.environment}-prometheus-grafana" : null
}

output "grafana_port" {
  description = "Grafana service port"
  value       = var.enable_grafana ? 80 : null
}

output "alertmanager_service_name" {
  description = "Name of the AlertManager service"
  value       = var.enable_alertmanager ? "${var.environment}-prometheus-kube-prometheus-alertmanager" : null
}

output "alertmanager_port" {
  description = "AlertManager service port"
  value       = var.enable_alertmanager ? 9093 : null
}

output "monitoring_namespace" {
  description = "Namespace where monitoring components are deployed"
  value       = var.monitoring_namespace
}

output "helm_release_info" {
  description = "Information about the Prometheus stack Helm release"
  value = var.enable_prometheus ? {
    name      = helm_release.prometheus_stack[0].name
    chart     = helm_release.prometheus_stack[0].chart
    version   = helm_release.prometheus_stack[0].version
    namespace = helm_release.prometheus_stack[0].namespace
    status    = helm_release.prometheus_stack[0].status
  } : null
}

output "grafana_admin_credentials" {
  description = "Grafana admin credentials"
  value = var.enable_grafana ? {
    username = "admin"
    password = var.grafana_config.admin_password
  } : null
  sensitive = true
}

output "service_urls" {
  description = "Service URLs for accessing monitoring components"
  value = {
    prometheus = var.enable_prometheus ? "http://${var.environment}-prometheus-kube-prometheus-prometheus.${var.monitoring_namespace}.svc.cluster.local:9090" : null
    grafana    = var.enable_grafana ? "http://${var.environment}-prometheus-grafana.${var.monitoring_namespace}.svc.cluster.local" : null
    alertmanager = var.enable_alertmanager ? "http://${var.environment}-prometheus-kube-prometheus-alertmanager.${var.monitoring_namespace}.svc.cluster.local:9093" : null
  }
}

output "service_monitor_info" {
  description = "Information about created ServiceMonitor"
  value = var.enable_prometheus && var.enable_app_monitoring ? {
    name      = kubernetes_manifest.app_service_monitor[0].manifest.metadata.name
    namespace = kubernetes_manifest.app_service_monitor[0].manifest.metadata.namespace
  } : null
}

output "prometheus_rules_info" {
  description = "Information about created PrometheusRules"
  value = var.enable_prometheus && var.enable_app_monitoring ? {
    name      = kubernetes_manifest.app_prometheus_rules[0].manifest.metadata.name
    namespace = kubernetes_manifest.app_prometheus_rules[0].manifest.metadata.namespace
  } : null
}
