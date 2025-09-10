# modules/observability/main.tf
# Observability module - Prometheus monitoring stack

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

# Prometheus Operator using kube-prometheus-stack
resource "helm_release" "prometheus_stack" {
  count = var.enable_prometheus ? 1 : 0
  
  name       = "${var.environment}-prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "51.9.4"
  namespace  = var.monitoring_namespace
  
  create_namespace = true
  
  values = [yamlencode({
    # Global configuration
    global = {
      imageRegistry = ""
    }
    
    # Prometheus configuration
    prometheus = {
      prometheusSpec = {
        # COST ISSUE 5: Excessive metrics retention period (2 years instead of 15-30 days)
        retention = "2y"  # 2 years of metrics retention costs significant storage
        
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = var.storage_class
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = {
                  # COST ISSUE 5: Massive storage allocation for metrics
                  storage = "10Ti"  # 10 Terabytes for Prometheus storage
                }
              }
            }
          }
        }
        
        resources = var.prometheus_config.resources
        
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
        ruleSelectorNilUsesHelmValues          = false
        
        # Security context
        securityContext = {
          runAsNonRoot = true
          runAsUser    = 65534
          fsGroup      = 65534
        }
        
        # Additional scrape configs for custom services
        additionalScrapeConfigs = [
          {
            job_name = "kubernetes-services"
            kubernetes_sd_configs = [
              {
                role = "service"
                namespaces = {
                  names = [var.namespace, var.monitoring_namespace]
                }
              }
            ]
            relabel_configs = [
              {
                source_labels = ["__meta_kubernetes_service_annotation_prometheus_io_scrape"]
                action        = "keep"
                regex         = "true"
              },
              {
                source_labels = ["__meta_kubernetes_service_annotation_prometheus_io_path"]
                action        = "replace"
                target_label  = "__metrics_path__"
                regex         = "(.+)"
              }
            ]
          }
        ]
      }
      
      service = {
        type = "ClusterIP"
      }
    }
    
    # Grafana configuration
    grafana = {
      enabled = var.enable_grafana
      
      adminPassword = var.grafana_config.admin_password
      
      persistence = {
        enabled          = true
        storageClassName = var.storage_class
        size             = var.grafana_config.storage_size
      }
      
      resources = var.grafana_config.resources
      
      # Security context
      securityContext = {
        runAsNonRoot = true
        runAsUser    = 472
        fsGroup      = 472
      }
      
      # Default dashboards
      defaultDashboardsEnabled = true
      
      # Additional data sources
      additionalDataSources = [
        {
          name   = "Loki"
          type   = "loki"
          url    = "http://loki:3100"
          access = "proxy"
        }
      ]
      
      service = {
        type = "ClusterIP"
      }
      
      # Grafana configuration
      grafana_ini = {
        server = {
          root_url = "http://localhost:3000"
        }
        security = {
          admin_user     = "admin"
          admin_password = var.grafana_config.admin_password
        }
        auth = {
          disable_login_form = false
        }
      }
    }
    
    # AlertManager configuration
    alertmanager = {
      enabled = var.enable_alertmanager
      
      alertmanagerSpec = {
        storage = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = var.storage_class
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = var.alertmanager_config.storage_size
                }
              }
            }
          }
        }
        
        resources = var.alertmanager_config.resources
        
        # Security context
        securityContext = {
          runAsNonRoot = true
          runAsUser    = 65534
          fsGroup      = 65534
        }
      }
      
      service = {
        type = "ClusterIP"
      }
      
      config = {
        global = {
          smtp_smarthost = "localhost:587"
          smtp_from      = "alertmanager@${var.domain_name}"
        }
        
        route = {
          group_by        = ["alertname"]
          group_wait      = "10s"
          group_interval  = "10s"
          repeat_interval = "1h"
          receiver        = "web.hook"
        }
        
        receivers = [
          {
            name = "web.hook"
            webhook_configs = [
              {
                url = "http://127.0.0.1:5001/"
              }
            ]
          }
        ]
      }
    }
    
    # Node Exporter
    nodeExporter = {
      enabled = var.enable_node_exporter
    }
    
    # Kube State Metrics
    kubeStateMetrics = {
      enabled = true
    }
    
    # Common labels
    commonLabels = var.common_labels
  })]
  
  depends_on = [var.base_module_dependency]
}

# ServiceMonitor for application metrics
resource "kubernetes_manifest" "app_service_monitor" {
  count = var.enable_prometheus && var.enable_app_monitoring ? 1 : 0
  
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    
    metadata = {
      name      = "${var.environment}-app-metrics"
      namespace = var.monitoring_namespace
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "service-monitor"
        "release"                     = "${var.environment}-prometheus"
      })
    }
    
    spec = {
      selector = {
        matchLabels = {
          "prometheus.io/scrape" = "true"
        }
      }
      
      namespaceSelector = {
        matchNames = [var.namespace]
      }
      
      endpoints = [
        {
          port     = "metrics"
          interval = "30s"
          path     = "/metrics"
        }
      ]
    }
  }
  
  depends_on = [helm_release.prometheus_stack]
}

# PrometheusRule for application alerts
resource "kubernetes_manifest" "app_prometheus_rules" {
  count = var.enable_prometheus && var.enable_app_monitoring ? 1 : 0
  
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    
    metadata = {
      name      = "${var.environment}-app-rules"
      namespace = var.monitoring_namespace
      labels = merge(var.common_labels, {
        "app.kubernetes.io/component" = "prometheus-rules"
        "release"                     = "${var.environment}-prometheus"
      })
    }
    
    spec = {
      groups = [
        {
          name = "${var.environment}-app-alerts"
          rules = [
            {
              alert = "HighMemoryUsage"
              expr  = "container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.8"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High memory usage detected"
                description = "Container {{ $labels.container }} in pod {{ $labels.pod }} is using more than 80% of its memory limit"
              }
            },
            {
              alert = "HighCPUUsage"
              expr  = "rate(container_cpu_usage_seconds_total[5m]) / container_spec_cpu_quota * 100 > 80"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High CPU usage detected"
                description = "Container {{ $labels.container }} in pod {{ $labels.pod }} is using more than 80% of its CPU limit"
              }
            },
            {
              alert = "PodCrashLooping"
              expr  = "rate(kube_pod_container_status_restarts_total[15m]) > 0"
              for   = "5m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "Pod is crash looping"
                description = "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is restarting frequently"
              }
            },
            {
              alert = "DatabaseDown"
              expr  = "up{job=~\".*postgres.*|.*redis.*|.*clickhouse.*|.*minio.*\"} == 0"
              for   = "2m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "Database service is down"
                description = "Database service {{ $labels.job }} is not responding"
              }
            }
          ]
        }
      ]
    }
  }
  
  depends_on = [helm_release.prometheus_stack]
}

# Create ConfigMap with Grafana dashboard for application metrics
resource "kubernetes_config_map" "grafana_dashboard" {
  count = var.enable_prometheus && var.enable_grafana ? 1 : 0
  
  metadata {
    name      = "${var.environment}-app-dashboard"
    namespace = var.monitoring_namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component"     = "grafana-dashboard"
      "grafana_dashboard"               = "1"
    })
  }

  data = {
    "app-dashboard.json" = jsonencode({
      dashboard = {
        id       = null
        title    = "${title(var.environment)} Application Dashboard"
        tags     = ["kubernetes", var.environment]
        timezone = "browser"
        panels = [
          {
            id    = 1
            title = "CPU Usage"
            type  = "graph"
            targets = [
              {
                expr = "rate(container_cpu_usage_seconds_total{namespace=\"${var.namespace}\"}[5m]) * 100"
                legendFormat = "{{ pod }}"
              }
            ]
            yAxes = [
              {
                label = "CPU %"
                min   = 0
                max   = 100
              }
            ]
          },
          {
            id    = 2
            title = "Memory Usage"
            type  = "graph"
            targets = [
              {
                expr = "container_memory_usage_bytes{namespace=\"${var.namespace}\"} / 1024 / 1024"
                legendFormat = "{{ pod }}"
              }
            ]
            yAxes = [
              {
                label = "Memory MB"
                min   = 0
              }
            ]
          },
          {
            id    = 3
            title = "Network I/O"
            type  = "graph"
            targets = [
              {
                expr = "rate(container_network_receive_bytes_total{namespace=\"${var.namespace}\"}[5m])"
                legendFormat = "{{ pod }} - received"
              },
              {
                expr = "rate(container_network_transmit_bytes_total{namespace=\"${var.namespace}\"}[5m])"
                legendFormat = "{{ pod }} - transmitted"
              }
            ]
          }
        ]
        time = {
          from = "now-1h"
          to   = "now"
        }
        refresh = "30s"
      }
    })
  }
  
  depends_on = [helm_release.prometheus_stack]
}
