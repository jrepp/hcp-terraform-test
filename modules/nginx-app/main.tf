# modules/nginx-app/main.tf
# Nginx application module - demonstrates a simple web service

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Create ConfigMap for nginx configuration
resource "kubernetes_config_map" "nginx_config" {
  metadata {
    name      = "${var.environment}-nginx-config"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "nginx-config"
      "app.kubernetes.io/name"      = "nginx"
    })
  }

  data = {
    "nginx.conf" = <<-EOT
      user nginx;
      worker_processes auto;
      error_log /var/log/nginx/error.log notice;
      pid /var/run/nginx.pid;

      events {
          worker_connections 1024;
      }

      http {
          include /etc/nginx/mime.types;
          default_type application/octet-stream;

          log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

          access_log /var/log/nginx/access.log main;

          sendfile on;
          tcp_nopush on;
          keepalive_timeout 65;
          gzip on;

          # Health check endpoint
          server {
              listen 8080;
              server_name _;
              
              location /health {
                  access_log off;
                  return 200 "healthy\n";
                  add_header Content-Type text/plain;
              }
              
              location /ready {
                  access_log off;
                  return 200 "ready\n";
                  add_header Content-Type text/plain;
              }
              
              location /metrics {
                  access_log off;
                  stub_status on;
              }
          }

          # Main application server
          server {
              listen 80;
              server_name _;
              root /usr/share/nginx/html;
              index index.html;

              # Security headers
              add_header X-Frame-Options "SAMEORIGIN" always;
              add_header X-Content-Type-Options "nosniff" always;
              add_header X-XSS-Protection "1; mode=block" always;
              add_header Referrer-Policy "no-referrer-when-downgrade" always;

              location / {
                  try_files $uri $uri/ =404;
              }

              location /api {
                  proxy_pass http://${var.environment}-api:8080;
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
              }
          }
      }
    EOT
    
    "index.html" = <<-EOT
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>${title(var.environment)} - Kubernetes Demo</title>
          <style>
              body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                  margin: 0;
                  padding: 20px;
                  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  color: white;
                  min-height: 100vh;
              }
              .container {
                  max-width: 800px;
                  margin: 0 auto;
                  text-align: center;
              }
              .header {
                  margin-bottom: 40px;
              }
              h1 {
                  font-size: 3em;
                  margin-bottom: 10px;
                  text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
              }
              .subtitle {
                  font-size: 1.2em;
                  opacity: 0.9;
              }
              .info-grid {
                  display: grid;
                  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                  gap: 20px;
                  margin: 40px 0;
              }
              .info-card {
                  background: rgba(255, 255, 255, 0.1);
                  padding: 20px;
                  border-radius: 10px;
                  backdrop-filter: blur(10px);
              }
              .info-card h3 {
                  margin-top: 0;
                  color: #ffd700;
              }
              .status {
                  display: inline-block;
                  padding: 5px 15px;
                  background: #4caf50;
                  border-radius: 20px;
                  font-weight: bold;
                  margin: 10px 0;
              }
              .footer {
                  margin-top: 40px;
                  opacity: 0.8;
                  font-size: 0.9em;
              }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="header">
                  <h1>🚀 Kubernetes Demo</h1>
                  <div class="subtitle">Environment: ${title(var.environment)}</div>
                  <div class="status">✅ Service Running</div>
              </div>
              
              <div class="info-grid">
                  <div class="info-card">
                      <h3>🏗️ Infrastructure</h3>
                      <p>Deployed with Terraform<br>
                      Kubernetes ${var.cluster_type}<br>
                      Istio Service Mesh</p>
                  </div>
                  
                  <div class="info-card">
                      <h3>🔍 Observability</h3>
                      <p>Prometheus Monitoring<br>
                      Grafana Dashboards<br>
                      Distributed Tracing</p>
                  </div>
                  
                  <div class="info-card">
                      <h3>🗄️ Data Layer</h3>
                      <p>PostgreSQL Database<br>
                      Redis Cache<br>
                      ClickHouse Analytics<br>
                      MinIO Object Storage</p>
                  </div>
                  
                  <div class="info-card">
                      <h3>🔒 Security</h3>
                      <p>Network Policies<br>
                      mTLS Communication<br>
                      Topaz Authorization<br>
                      cert-manager TLS</p>
                  </div>
              </div>
              
              <div class="footer">
                  <p>Namespace: ${var.namespace} | Version: 1.0.0</p>
                  <p>Built with ❤️ using Terraform and Kubernetes</p>
              </div>
          </div>
      </body>
      </html>
    EOT
  }
  
  depends_on = [var.base_module_dependency]
}

# Create PersistentVolumeClaim for nginx logs
resource "kubernetes_persistent_volume_claim" "nginx_logs" {
  count = var.enable_persistent_logs ? 1 : 0
  
  metadata {
    name      = "${var.environment}-nginx-logs"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "nginx-logs"
      "app.kubernetes.io/name"      = "nginx"
    })
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    
    resources {
      requests = {
        storage = var.log_storage_size
      }
    }
    
    storage_class_name = var.storage_class
  }
  
  depends_on = [var.base_module_dependency]
}

# Create Deployment for nginx
resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "${var.environment}-nginx"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "web-server"
      "app.kubernetes.io/name"      = "nginx"
      "app.kubernetes.io/version"   = var.nginx_config.image_tag
    })
  }

  spec {
    replicas = var.nginx_config.replica_count

    selector {
      match_labels = {
        "app.kubernetes.io/name"      = "nginx"
        "app.kubernetes.io/component" = "web-server"
      }
    }

    template {
      metadata {
        labels = merge(var.common_labels, {
          "app.kubernetes.io/name"      = "nginx"
          "app.kubernetes.io/component" = "web-server"
          "app"                         = "nginx"  # For Istio
        })
        
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "8080"
          "prometheus.io/path"   = "/metrics"
          "sidecar.istio.io/inject" = var.enable_istio_injection ? "true" : "false"
        }
      }

      spec {
        service_account_name = var.service_account_name
        
        security_context {
          run_as_non_root = true
          run_as_user     = 101  # nginx user
          fs_group        = 101
        }

        container {
          name  = "nginx"
          image = "${var.nginx_config.image_repository}:${var.nginx_config.image_tag}"
          
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 80
            protocol       = "TCP"
          }
          
          port {
            name           = "metrics"
            container_port = 8080
            protocol       = "TCP"
          }

          env {
            name  = "NGINX_ENVSUBST_OUTPUT_DIR"
            value = "/etc/nginx"
          }
          
          env {
            name  = "ENVIRONMENT"
            value = var.environment
          }
          
          env {
            name  = "CLUSTER_TYPE"
            value = var.cluster_type
          }

          resources {
            requests = {
              cpu    = var.nginx_config.resources.requests.cpu
              memory = var.nginx_config.resources.requests.memory
            }
            limits = {
              cpu    = var.nginx_config.resources.limits.cpu
              memory = var.nginx_config.resources.limits.memory
            }
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
            read_only  = true
          }
          
          volume_mount {
            name       = "nginx-html"
            mount_path = "/usr/share/nginx/html/index.html"
            sub_path   = "index.html"
            read_only  = true
          }
          
          # Persistent logs if enabled
          dynamic "volume_mount" {
            for_each = var.enable_persistent_logs ? [1] : []
            content {
              name       = "nginx-logs"
              mount_path = "/var/log/nginx"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
          
          security_context {
            allow_privilege_escalation = false
            run_as_non_root           = true
            run_as_user               = 101
            read_only_root_filesystem = false  # nginx needs to write to /var/cache/nginx
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.nginx_config.metadata[0].name
          }
        }
        
        volume {
          name = "nginx-html"
          config_map {
            name = kubernetes_config_map.nginx_config.metadata[0].name
          }
        }
        
        # Persistent logs volume if enabled
        dynamic "volume" {
          for_each = var.enable_persistent_logs ? [1] : []
          content {
            name = "nginx-logs"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.nginx_logs[0].metadata[0].name
            }
          }
        }
        
        restart_policy = "Always"
        
        # Node selection and affinity
        node_selector = var.nginx_config.node_selector
        
        dynamic "toleration" {
          for_each = var.nginx_config.tolerations
          content {
            key      = toleration.value.key
            operator = toleration.value.operator
            value    = toleration.value.value
            effect   = toleration.value.effect
          }
        }
        
        # Pod anti-affinity for better distribution
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["nginx"]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }
      }
    }
  }
  
  depends_on = [kubernetes_config_map.nginx_config]
}

# Create Service for nginx
resource "kubernetes_service" "nginx" {
  metadata {
    name      = "${var.environment}-nginx"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "web-server"
      "app.kubernetes.io/name"      = "nginx"
    })
    
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "8080"
      "prometheus.io/path"   = "/metrics"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name"      = "nginx"
      "app.kubernetes.io/component" = "web-server"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
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
  
  depends_on = [kubernetes_deployment.nginx]
}

# Create HPA for nginx (if enabled)
resource "kubernetes_horizontal_pod_autoscaler_v2" "nginx" {
  count = var.nginx_config.enable_hpa ? 1 : 0
  
  metadata {
    name      = "${var.environment}-nginx"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "nginx-hpa"
    })
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.nginx.metadata[0].name
    }

    # COST ISSUE 3: Aggressive auto-scaling configuration
    min_replicas = 50   # Minimum 50 pods always running (was likely 1-3)
    max_replicas = 500  # Can scale up to 500 pods (was likely 10-20)

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          # Scales up at very low CPU usage (5% instead of typical 70%)
          average_utilization = 5  
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          # Scales up at very low memory usage (10% instead of typical 80%)
          average_utilization = 10
        }
      }
    }
  }
  
  depends_on = [kubernetes_deployment.nginx]
}
