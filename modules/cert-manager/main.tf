# modules/cert-manager/main.tf
# cert-manager module for TLS certificate management

terraform {
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

# Install cert-manager using Helm
resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0
  
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_config.version
  namespace  = var.cert_manager_namespace
  
  create_namespace = true
  
  values = [yamlencode({
    installCRDs = true
    
    global = {
      logLevel = var.cert_manager_config.log_level
    }
    
    resources = var.cert_manager_config.resources
    
    # Security context
    securityContext = {
      runAsNonRoot = true
    }
    
    webhook = {
      resources = var.cert_manager_config.webhook_resources
      securityContext = {
        runAsNonRoot = true
      }
    }
    
    cainjector = {
      resources = var.cert_manager_config.cainjector_resources
      securityContext = {
        runAsNonRoot = true
      }
    }
    
    # Prometheus monitoring
    prometheus = {
      enabled = var.enable_monitoring
      servicemonitor = {
        enabled = var.enable_monitoring
        labels = var.common_labels
      }
    }
    
    # Node selection
    nodeSelector = var.cert_manager_config.node_selector
    tolerations  = var.cert_manager_config.tolerations
  })]
  
  depends_on = [var.base_module_dependency]
}

# Create ClusterIssuer for Let's Encrypt staging
resource "kubernetes_manifest" "letsencrypt_staging_issuer" {
  count = var.enable_cert_manager && var.enable_letsencrypt ? 1 : 0
  
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    
    metadata = {
      name = "letsencrypt-staging"
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "cluster-issuer"
        "issuer.type"                 = "letsencrypt-staging"
      })
    }
    
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_config.email
        
        privateKeySecretRef = {
          name = "letsencrypt-staging-private-key"
        }
        
        solvers = [
          {
            http01 = {
              ingress = {
                class = var.letsencrypt_config.ingress_class
              }
            }
          }
        ]
      }
    }
  }
  
  depends_on = [helm_release.cert_manager]
}

# Create ClusterIssuer for Let's Encrypt production
resource "kubernetes_manifest" "letsencrypt_prod_issuer" {
  count = var.enable_cert_manager && var.enable_letsencrypt ? 1 : 0
  
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    
    metadata = {
      name = "letsencrypt-prod"
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "cluster-issuer"
        "issuer.type"                 = "letsencrypt-prod"
      })
    }
    
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_config.email
        
        privateKeySecretRef = {
          name = "letsencrypt-prod-private-key"
        }
        
        solvers = [
          {
            http01 = {
              ingress = {
                class = var.letsencrypt_config.ingress_class
              }
            }
          }
        ]
      }
    }
  }
  
  depends_on = [helm_release.cert_manager]
}

# Create self-signed ClusterIssuer for development
resource "kubernetes_manifest" "selfsigned_issuer" {
  count = var.enable_cert_manager && var.enable_selfsigned ? 1 : 0
  
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    
    metadata = {
      name = "selfsigned-issuer"
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "cluster-issuer"
        "issuer.type"                 = "selfsigned"
      })
    }
    
    spec = {
      selfSigned = {}
    }
  }
  
  depends_on = [helm_release.cert_manager]
}

# Create root CA certificate for development
resource "kubernetes_manifest" "root_ca_cert" {
  count = var.enable_cert_manager && var.enable_selfsigned ? 1 : 0
  
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    
    metadata = {
      name      = "root-ca"
      namespace = var.cert_manager_namespace
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "root-ca"
      })
    }
    
    spec = {
      isCA       = true
      commonName = "Root CA"
      
      subject = {
        organizationalUnits = ["Development"]
        organizations       = ["Local Development"]
        countries          = ["US"]
      }
      
      duration    = "8760h"  # 1 year
      renewBefore = "720h"   # 30 days
      
      secretName = "root-ca-secret"
      
      issuerRef = {
        name = "selfsigned-issuer"
        kind = "ClusterIssuer"
      }
    }
  }
  
  depends_on = [kubernetes_manifest.selfsigned_issuer]
}

# Create CA ClusterIssuer using the root CA
resource "kubernetes_manifest" "ca_issuer" {
  count = var.enable_cert_manager && var.enable_selfsigned ? 1 : 0
  
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    
    metadata = {
      name = "ca-issuer"
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "cluster-issuer"
        "issuer.type"                 = "ca"
      })
    }
    
    spec = {
      ca = {
        secretName = "root-ca-secret"
      }
    }
  }
  
  depends_on = [kubernetes_manifest.root_ca_cert]
}

# Create certificate for the application
resource "kubernetes_manifest" "app_certificate" {
  count = var.enable_cert_manager && var.create_app_certificate ? 1 : 0
  
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    
    metadata = {
      name      = "${var.environment}-tls-cert"
      namespace = var.namespace
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "tls-certificate"
      })
    }
    
    spec = {
      commonName = var.app_certificate_config.common_name
      dnsNames   = var.app_certificate_config.dns_names
      
      duration    = var.app_certificate_config.duration
      renewBefore = var.app_certificate_config.renew_before
      
      secretName = "${var.environment}-tls-cert"
      
      issuerRef = {
        name = var.app_certificate_config.issuer_name
        kind = "ClusterIssuer"
      }
      
      usages = [
        "digital signature",
        "key encipherment",
        "server auth"
      ]
    }
  }
  
  depends_on = [
    kubernetes_manifest.letsencrypt_staging_issuer,
    kubernetes_manifest.letsencrypt_prod_issuer,
    kubernetes_manifest.ca_issuer
  ]
}

# Create NetworkPolicy for cert-manager (if enabled)
resource "kubernetes_network_policy" "cert_manager" {
  count = var.enable_cert_manager && var.enable_network_policies ? 1 : 0
  
  metadata {
    name      = "cert-manager-netpol"
    namespace = var.cert_manager_namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "cert-manager-network-policy"
    })
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "cert-manager"
      }
    }

    policy_types = ["Ingress", "Egress"]

    # Allow ingress from webhook
    ingress {
      from {
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = "webhook"
          }
        }
      }
      
      ports {
        port     = "9402"
        protocol = "TCP"
      }
    }

    # Allow egress to Kubernetes API
    egress {
      to {}
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }
    
    # Allow egress to Let's Encrypt
    egress {
      to {}
      ports {
        port     = "80"
        protocol = "TCP"
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }
    
    # Allow DNS
    egress {
      to {}
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
  
  depends_on = [helm_release.cert_manager]
}
