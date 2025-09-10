# modules/networking/main.tf
# Networking module - Istio service mesh, Envoy, and ingress

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

# Istio Base (CRDs and cluster roles)
resource "helm_release" "istio_base" {
  count = var.enable_istio ? 1 : 0
  
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = var.istio_config.version
  namespace  = var.istio_system_namespace
  
  create_namespace = true
  
  values = [yamlencode({
    global = {
      istioNamespace = var.istio_system_namespace
    }
  })]
}

# Istio Control Plane (istiod)
resource "helm_release" "istiod" {
  count = var.enable_istio ? 1 : 0
  
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = var.istio_config.version
  namespace  = var.istio_system_namespace
  
  values = [yamlencode({
    global = {
      meshID      = var.istio_config.mesh_id
      network     = var.istio_config.network_name
      hub         = var.istio_config.hub
      tag         = var.istio_config.tag
    }
    
    pilot = {
      resources = var.istio_config.pilot_resources
      
      # Security settings
      env = {
        EXTERNAL_ISTIOD = false
        PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION = true
      }
    }
    
    # Telemetry configuration
    telemetry = {
      v2 = {
        enabled = var.enable_monitoring
        prometheus = {
          configOverride = {
            metric_relabeling_configs = [
              {
                source_labels = ["__name__"]
                regex         = "istio_.*"
                target_label  = "__tmp_istio_metric"
              }
            ]
          }
        }
      }
    }
  })]
  
  depends_on = [helm_release.istio_base]
}

# Istio Ingress Gateway
resource "helm_release" "istio_gateway" {
  count = var.enable_istio && var.enable_istio_gateway ? 1 : 0
  
  name       = "istio-gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = var.istio_config.version
  namespace  = var.namespace
  
  values = [yamlencode({
    service = {
      type = var.gateway_config.service_type
      ports = [
        {
          name       = "http"
          port       = 80
          protocol   = "TCP"
          targetPort = 8080
        },
        {
          name       = "https"
          port       = 443
          protocol   = "TCP"
          targetPort = 8443
        }
      ]
      
      annotations = var.gateway_config.service_annotations
    }
    
    resources = var.gateway_config.resources
    
    replicaCount = var.gateway_config.replica_count
    
    autoscaling = var.gateway_config.enable_hpa ? {
      enabled                        = true
      minReplicas                   = var.gateway_config.hpa_config.min_replicas
      maxReplicas                   = var.gateway_config.hpa_config.max_replicas
      targetCPUUtilizationPercentage = var.gateway_config.hpa_config.target_cpu_utilization
    } : {
      enabled = false
    }
    
    # Security context
    securityContext = {
      capabilities = {
        drop = ["ALL"]
      }
      runAsNonRoot = true
      runAsUser    = 1337
      runAsGroup   = 1337
    }
    
    # Node selection
    nodeSelector = var.gateway_config.node_selector
    tolerations  = var.gateway_config.tolerations
  })]
  
  depends_on = [helm_release.istiod]
}

# Enable Istio injection for the application namespace
resource "kubernetes_labels" "namespace_istio_injection" {
  count = var.enable_istio ? 1 : 0
  
  api_version = "v1"
  kind        = "Namespace"
  
  metadata {
    name = var.namespace
  }
  
  labels = {
    "istio-injection" = "enabled"
  }
  
  depends_on = [helm_release.istiod]
}

# Gateway configuration for ingress traffic
resource "kubernetes_manifest" "istio_gateway" {
  count = var.enable_istio && var.enable_istio_gateway ? 1 : 0
  
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    
    metadata = {
      name      = "${var.environment}-gateway"
      namespace = var.namespace
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "gateway"
      })
    }
    
    spec = {
      selector = {
        istio = "gateway"
      }
      
      servers = [
        {
          port = {
            number   = 80
            name     = "http"
            protocol = "HTTP"
          }
          hosts = var.gateway_config.hosts
          
          # Redirect HTTP to HTTPS if TLS is enabled
          dynamic "tls" {
            for_each = var.enable_tls ? [1] : []
            content {
              httpsRedirect = true
            }
          }
        }
      ]
      
      # HTTPS server if TLS is enabled
      dynamic "servers" {
        for_each = var.enable_tls ? [1] : []
        content {
          port = {
            number   = 443
            name     = "https"
            protocol = "HTTPS"
          }
          hosts = var.gateway_config.hosts
          tls = {
            mode           = "SIMPLE"
            credentialName = "${var.environment}-tls-cert"
          }
        }
      }
    }
  }
  
  depends_on = [helm_release.istio_gateway]
}

# Virtual Service for application routing
resource "kubernetes_manifest" "app_virtual_service" {
  count = var.enable_istio && var.enable_istio_gateway ? 1 : 0
  
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    
    metadata = {
      name      = "${var.environment}-app-vs"
      namespace = var.namespace
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "virtual-service"
      })
    }
    
    spec = {
      hosts = var.gateway_config.hosts
      gateways = [
        "${var.environment}-gateway"
      ]
      
      http = [
        {
          name = "nginx-route"
          match = [
            {
              uri = {
                prefix = "/"
              }
            }
          ]
          route = [
            {
              destination = {
                host = "${var.environment}-nginx"
                port = {
                  number = 80
                }
              }
            }
          ]
        },
        {
          name = "api-route"
          match = [
            {
              uri = {
                prefix = "/api"
              }
            }
          ]
          route = [
            {
              destination = {
                host = "${var.environment}-api"
                port = {
                  number = 8080
                }
              }
            }
          ]
        }
      ]
    }
  }
  
  depends_on = [kubernetes_manifest.istio_gateway]
}

# Destination Rules for traffic policies
resource "kubernetes_manifest" "app_destination_rule" {
  count = var.enable_istio ? 1 : 0
  
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "DestinationRule"
    
    metadata = {
      name      = "${var.environment}-app-dr"
      namespace = var.namespace
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "destination-rule"
      })
    }
    
    spec = {
      host = "${var.environment}-nginx"
      
      trafficPolicy = {
        connectionPool = {
          tcp = {
            maxConnections = 100
          }
          http = {
            http1MaxPendingRequests  = 50
            http2MaxRequests        = 100
            maxRequestsPerConnection = 2
            maxRetries              = 3
            consecutiveGatewayErrors = 5
          }
        }
        
        loadBalancer = {
          simple = "LEAST_CONN"
        }
        
        outlierDetection = {
          consecutiveGatewayErrors = 5
          consecutive5xxErrors     = 5
          interval                = "30s"
          baseEjectionTime        = "30s"
          maxEjectionPercent      = 50
          minHealthPercent        = 50
        }
      }
    }
  }
  
  depends_on = [helm_release.istiod]
}

# PeerAuthentication for mTLS
resource "kubernetes_manifest" "peer_authentication" {
  count = var.enable_istio && var.istio_config.enable_mtls ? 1 : 0
  
  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    
    metadata = {
      name      = "${var.environment}-default"
      namespace = var.namespace
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "peer-authentication"
      })
    }
    
    spec = {
      mtls = {
        mode = var.istio_config.mtls_mode
      }
    }
  }
  
  depends_on = [helm_release.istiod]
}

# AuthorizationPolicy for access control
resource "kubernetes_manifest" "authorization_policy" {
  count = var.enable_istio && var.enable_authorization ? 1 : 0
  
  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "AuthorizationPolicy"
    
    metadata = {
      name      = "${var.environment}-authz"
      namespace = var.namespace
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "authorization-policy"
      })
    }
    
    spec = {
      action = "ALLOW"
      
      rules = [
        {
          # Allow traffic to nginx
          to = [
            {
              operation = {
                methods = ["GET", "POST"]
              }
            }
          ]
          when = [
            {
              key    = "destination.labels[app]"
              values = ["nginx"]
            }
          ]
        },
        {
          # Allow monitoring traffic
          to = [
            {
              operation = {
                methods = ["GET"]
                paths   = ["/metrics", "/health", "/ready"]
              }
            }
          ]
        }
      ]
    }
  }
  
  depends_on = [helm_release.istiod]
}

# ServiceEntry for external services
resource "kubernetes_manifest" "external_services" {
  for_each = var.enable_istio ? var.external_services : {}
  
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "ServiceEntry"
    
    metadata = {
      name      = "${var.environment}-${each.key}"
      namespace = var.namespace
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "service-entry"
      })
    }
    
    spec = {
      hosts = each.value.hosts
      ports = each.value.ports
      location = each.value.location
      resolution = each.value.resolution
    }
  }
  
  depends_on = [helm_release.istiod]
}

# Telemetry configuration for observability
resource "kubernetes_manifest" "telemetry_config" {
  count = var.enable_istio && var.enable_monitoring ? 1 : 0
  
  manifest = {
    apiVersion = "telemetry.istio.io/v1alpha1"
    kind       = "Telemetry"
    
    metadata = {
      name      = "${var.environment}-telemetry"
      namespace = var.namespace
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "telemetry"
      })
    }
    
    spec = {
      metrics = [
        {
          providers = [
            {
              name = "prometheus"
            }
          ]
          overrides = [
            {
              match = {
                metric = "ALL_METRICS"
              }
              tagOverrides = {
                "destination_app" = {
                  value = "destination.labels['app'] | 'unknown'"
                }
                "source_app" = {
                  value = "source.labels['app'] | 'unknown'"
                }
              }
            }
          ]
        }
      ]
      
      tracing = var.enable_tracing ? [
        {
          providers = [
            {
              name = "jaeger"
            }
          ]
          randomSamplingPercentage = var.tracing_config.sampling_rate
        }
      ] : []
    }
  }
  
  depends_on = [helm_release.istiod]
}
