# modules/security/main.tf
# Security module - Topaz.sh (OpenFGA) authorization and security components

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

# Create ConfigMap for Topaz configuration
resource "kubernetes_config_map" "topaz_config" {
  count = var.enable_topaz ? 1 : 0
  
  metadata {
    name      = "${var.environment}-topaz-config"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "topaz-config"
      "app.kubernetes.io/name"      = "topaz"
    })
  }

  data = {
    "config.yaml" = yamlencode({
      # Topaz configuration
      logging = {
        prod = true
        log_level = var.topaz_config.log_level
      }
      
      directory = {
        db = {
          driver = "postgres"
          dsn = "postgres://${var.database_config.username}:${var.database_config.password}@${var.database_config.host}:${var.database_config.port}/${var.database_config.database}?sslmode=disable"
        }
        
        # Directory service configuration
        grpc = {
          listen_address = "0.0.0.0:9292"
          tls = {
            cert_path = "/app/certs/tls.crt"
            key_path  = "/app/certs/tls.key"
          }
        }
        
        gateway = {
          listen_address = "0.0.0.0:9393"
          allowed_origins = var.topaz_config.allowed_origins
        }
      }
      
      authorizer = {
        grpc = {
          listen_address = "0.0.0.0:8282"
          tls = {
            cert_path = "/app/certs/tls.crt"
            key_path  = "/app/certs/tls.key"
          }
        }
        
        gateway = {
          listen_address = "0.0.0.0:8383"
          allowed_origins = var.topaz_config.allowed_origins
        }
      }
      
      # Model configuration
      model = {
        name = var.topaz_config.model_name
        version = "1.0"
      }
    })
  }
  
  depends_on = [var.base_module_dependency]
}

# Create Secret for Topaz TLS certificates
resource "kubernetes_secret" "topaz_tls" {
  count = var.enable_topaz ? 1 : 0
  
  metadata {
    name      = "${var.environment}-topaz-tls"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "topaz-tls"
    })
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = var.topaz_config.tls_cert
    "tls.key" = var.topaz_config.tls_key
  }
  
  depends_on = [var.base_module_dependency]
}

# Create Deployment for Topaz
resource "kubernetes_deployment" "topaz" {
  count = var.enable_topaz ? 1 : 0
  
  metadata {
    name      = "${var.environment}-topaz"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "authorization"
      "app.kubernetes.io/name"      = "topaz"
      "app.kubernetes.io/version"   = var.topaz_config.image_tag
    })
  }

  spec {
    replicas = var.topaz_config.replica_count

    selector {
      match_labels = {
        "app.kubernetes.io/name"      = "topaz"
        "app.kubernetes.io/component" = "authorization"
      }
    }

    template {
      metadata {
        labels = merge(var.common_labels, {
          "app.kubernetes.io/name"      = "topaz"
          "app.kubernetes.io/component" = "authorization"
        })
        
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "8080"
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        service_account_name = var.service_account_name
        
        security_context {
          run_as_non_root = true
          run_as_user     = 65534
          fs_group        = 65534
        }

        container {
          name  = "topaz"
          image = "${var.topaz_config.image_repository}:${var.topaz_config.image_tag}"
          
          image_pull_policy = "IfNotPresent"

          port {
            name           = "authz-grpc"
            container_port = 8282
            protocol       = "TCP"
          }
          
          port {
            name           = "authz-gateway"
            container_port = 8383
            protocol       = "TCP"
          }
          
          port {
            name           = "directory-grpc"
            container_port = 9292
            protocol       = "TCP"
          }
          
          port {
            name           = "directory-gateway"
            container_port = 9393
            protocol       = "TCP"
          }
          
          port {
            name           = "metrics"
            container_port = 8080
            protocol       = "TCP"
          }

          env {
            name  = "TOPAZ_CFG"
            value = "/app/config/config.yaml"
          }
          
          env {
            name  = "TOPAZ_DB_MIGRATE"
            value = "true"
          }

          resources {
            requests = {
              cpu    = var.topaz_config.resources.requests.cpu
              memory = var.topaz_config.resources.requests.memory
            }
            limits = {
              cpu    = var.topaz_config.resources.limits.cpu
              memory = var.topaz_config.resources.limits.memory
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/app/config"
            read_only  = true
          }
          
          volume_mount {
            name       = "tls"
            mount_path = "/app/certs"
            read_only  = true
          }

          liveness_probe {
            grpc {
              port = 8282
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            grpc {
              port = 8282
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
          
          security_context {
            allow_privilege_escalation = false
            run_as_non_root           = true
            run_as_user               = 65534
            read_only_root_filesystem = true
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.topaz_config[0].metadata[0].name
          }
        }
        
        volume {
          name = "tls"
          secret {
            secret_name = kubernetes_secret.topaz_tls[0].metadata[0].name
          }
        }
        
        restart_policy = "Always"
        
        # Node selection and affinity
        node_selector = var.topaz_config.node_selector
        
        dynamic "toleration" {
          for_each = var.topaz_config.tolerations
          content {
            key      = toleration.value.key
            operator = toleration.value.operator
            value    = toleration.value.value
            effect   = toleration.value.effect
          }
        }
      }
    }
  }
  
  depends_on = [kubernetes_config_map.topaz_config, kubernetes_secret.topaz_tls]
}

# Create Service for Topaz
resource "kubernetes_service" "topaz" {
  count = var.enable_topaz ? 1 : 0
  
  metadata {
    name      = "${var.environment}-topaz"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "authorization"
      "app.kubernetes.io/name"      = "topaz"
    })
    
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "8080"
      "prometheus.io/path"   = "/metrics"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name"      = "topaz"
      "app.kubernetes.io/component" = "authorization"
    }

    port {
      name        = "authz-grpc"
      port        = 8282
      target_port = 8282
      protocol    = "TCP"
    }
    
    port {
      name        = "authz-gateway"
      port        = 8383
      target_port = 8383
      protocol    = "TCP"
    }
    
    port {
      name        = "directory-grpc"
      port        = 9292
      target_port = 9292
      protocol    = "TCP"
    }
    
    port {
      name        = "directory-gateway"
      port        = 9393
      target_port = 9393
      protocol    = "TCP"
    }
    
    port {
      name        = "metrics"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
  
  depends_on = [kubernetes_deployment.topaz]
}

# Create HPA for Topaz (if enabled)
resource "kubernetes_horizontal_pod_autoscaler_v2" "topaz" {
  count = var.enable_topaz && var.topaz_config.enable_hpa ? 1 : 0
  
  metadata {
    name      = "${var.environment}-topaz"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "topaz-hpa"
    })
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.topaz[0].metadata[0].name
    }

    min_replicas = var.topaz_config.hpa_config.min_replicas
    max_replicas = var.topaz_config.hpa_config.max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.topaz_config.hpa_config.target_cpu_utilization
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.topaz_config.hpa_config.target_memory_utilization
        }
      }
    }
  }
  
  depends_on = [kubernetes_deployment.topaz]
}

# Create PodDisruptionBudget for Topaz
resource "kubernetes_pod_disruption_budget_v1" "topaz" {
  count = var.enable_topaz && var.topaz_config.replica_count > 1 ? 1 : 0
  
  metadata {
    name      = "${var.environment}-topaz"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "topaz-pdb"
    })
  }
  
  spec {
    min_available = var.topaz_config.pdb_min_available
    
    selector {
      match_labels = {
        "app.kubernetes.io/name"      = "topaz"
        "app.kubernetes.io/component" = "authorization"
      }
    }
  }
  
  depends_on = [kubernetes_deployment.topaz]
}

# Create NetworkPolicy for Topaz (if enabled)
resource "kubernetes_network_policy" "topaz" {
  count = var.enable_topaz && var.enable_network_policies ? 1 : 0
  
  metadata {
    name      = "${var.environment}-topaz-netpol"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "topaz-network-policy"
    })
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name"      = "topaz"
        "app.kubernetes.io/component" = "authorization"
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = var.namespace
          }
        }
      }
      
      ports {
        port     = "8282"
        protocol = "TCP"
      }
      
      ports {
        port     = "8383"
        protocol = "TCP"
      }
      
      ports {
        port     = "9292"
        protocol = "TCP"
      }
      
      ports {
        port     = "9393"
        protocol = "TCP"
      }
    }

    egress {
      # Allow access to PostgreSQL
      to {
        namespace_selector {
          match_labels = {
            name = var.namespace
          }
        }
      }
      
      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }
    
    egress {
      # Allow DNS
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
  
  depends_on = [kubernetes_deployment.topaz]
}
