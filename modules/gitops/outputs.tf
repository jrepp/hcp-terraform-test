# modules/gitops/outputs.tf
# Outputs for the gitops module

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = var.argocd_namespace
}

output "argocd_release_info" {
  description = "ArgoCD Helm release information"
  value = var.enable_argocd ? {
    name      = helm_release.argocd[0].name
    chart     = helm_release.argocd[0].chart
    version   = helm_release.argocd[0].version
    namespace = helm_release.argocd[0].namespace
    status    = helm_release.argocd[0].status
  } : null
}

output "argocd_server_service_name" {
  description = "ArgoCD server service name"
  value       = var.enable_argocd ? "argocd-server" : null
}

output "argocd_server_port" {
  description = "ArgoCD server port"
  value       = var.enable_argocd ? 80 : null
}

output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = var.enable_argocd ? var.argocd_config.server_url : null
}

output "argocd_admin_password_secret" {
  description = "Name of the secret containing ArgoCD admin password"
  value       = var.enable_argocd && var.argocd_config.admin_password != "" ? "argocd-initial-admin-secret" : null
}

output "argocd_projects" {
  description = "Created ArgoCD projects"
  value       = var.enable_argocd ? keys(var.argocd_projects) : []
}

output "argocd_applications" {
  description = "Created ArgoCD applications"
  value       = var.enable_argocd ? keys(var.argocd_applications) : []
}

output "argocd_ingress_info" {
  description = "ArgoCD ingress information"
  value = var.enable_argocd && var.enable_argocd_ingress ? {
    hostname      = var.argocd_ingress_config.hostname
    ingress_class = var.argocd_ingress_config.ingress_class
    tls_enabled   = var.argocd_ingress_config.enable_tls
    tls_secret    = var.argocd_ingress_config.enable_tls ? "${var.environment}-argocd-tls" : null
  } : null
}

output "argocd_oidc_info" {
  description = "ArgoCD OIDC configuration information"
  value = var.enable_argocd && var.enable_oidc ? {
    enabled               = true
    issuer               = var.oidc_config.issuer
    client_id            = var.oidc_config.client_id
    requested_scopes     = var.oidc_config.requested_scopes
  } : {
    enabled = false
  }
  sensitive = true
}

output "argocd_rbac_info" {
  description = "ArgoCD RBAC configuration information"
  value = var.enable_argocd ? {
    default_policy = var.rbac_config.default_policy
    scopes        = var.rbac_config.scopes
  } : null
}

output "argocd_network_policy_info" {
  description = "Information about ArgoCD network policy"
  value = var.enable_argocd && var.enable_network_policies ? {
    name      = "argocd-netpol"
    namespace = var.argocd_namespace
  } : null
}

output "argocd_service_urls" {
  description = "ArgoCD service URLs"
  value = var.enable_argocd ? {
    server     = "http://argocd-server.${var.argocd_namespace}.svc.cluster.local"
    repo_server = "argocd-repo-server.${var.argocd_namespace}.svc.cluster.local:8081"
    redis      = "argocd-redis.${var.argocd_namespace}.svc.cluster.local:6379"
  } : null
}

output "argocd_cli_info" {
  description = "Information for ArgoCD CLI usage"
  value = var.enable_argocd ? {
    server_address = var.argocd_config.server_url
    admin_username = "admin"
    admin_password_secret = var.argocd_config.admin_password != "" ? "argocd-initial-admin-secret" : null
    cli_commands = {
      login = "argocd login ${var.argocd_config.server_url} --username admin --password <password>"
      port_forward = "kubectl port-forward svc/argocd-server -n ${var.argocd_namespace} 8080:80"
    }
  } : null
}
