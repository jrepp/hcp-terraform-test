# modules/cert-manager/outputs.tf
# Outputs for the cert-manager module

output "cert_manager_namespace" {
  description = "cert-manager namespace"
  value       = var.cert_manager_namespace
}

output "cert_manager_release_info" {
  description = "cert-manager Helm release information"
  value = var.enable_cert_manager ? {
    name      = helm_release.cert_manager[0].name
    chart     = helm_release.cert_manager[0].chart
    version   = helm_release.cert_manager[0].version
    namespace = helm_release.cert_manager[0].namespace
    status    = helm_release.cert_manager[0].status
  } : null
}

output "cluster_issuers" {
  description = "Available ClusterIssuers"
  value = {
    letsencrypt_staging = var.enable_cert_manager && var.enable_letsencrypt ? "letsencrypt-staging" : null
    letsencrypt_prod    = var.enable_cert_manager && var.enable_letsencrypt ? "letsencrypt-prod" : null
    selfsigned          = var.enable_cert_manager && var.enable_selfsigned ? "selfsigned-issuer" : null
    ca_issuer           = var.enable_cert_manager && var.enable_selfsigned ? "ca-issuer" : null
  }
}

output "app_certificate_name" {
  description = "Name of the application certificate"
  value       = var.enable_cert_manager && var.create_app_certificate ? "${var.environment}-tls-cert" : null
}

output "app_certificate_secret_name" {
  description = "Name of the secret containing the application certificate"
  value       = var.enable_cert_manager && var.create_app_certificate ? "${var.environment}-tls-cert" : null
}

output "root_ca_secret_name" {
  description = "Name of the root CA secret"
  value       = var.enable_cert_manager && var.enable_selfsigned ? "root-ca-secret" : null
}

output "certificate_info" {
  description = "Certificate configuration information"
  value = var.enable_cert_manager && var.create_app_certificate ? {
    common_name   = var.app_certificate_config.common_name
    dns_names     = var.app_certificate_config.dns_names
    duration      = var.app_certificate_config.duration
    renew_before  = var.app_certificate_config.renew_before
    issuer_name   = var.app_certificate_config.issuer_name
    secret_name   = "${var.environment}-tls-cert"
  } : null
}

output "letsencrypt_info" {
  description = "Let's Encrypt configuration information"
  value = var.enable_cert_manager && var.enable_letsencrypt ? {
    email         = var.letsencrypt_config.email
    ingress_class = var.letsencrypt_config.ingress_class
    staging_issuer = "letsencrypt-staging"
    prod_issuer    = "letsencrypt-prod"
  } : null
  sensitive = true
}

output "network_policy_info" {
  description = "Information about cert-manager network policy"
  value = var.enable_cert_manager && var.enable_network_policies ? {
    name      = "cert-manager-netpol"
    namespace = var.cert_manager_namespace
  } : null
}
