# modules/kubernetes-base/main.tf
# Base Kubernetes resources module
# This module creates fundamental Kubernetes resources needed by all environments

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Create namespace for the application
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.namespace
    
    labels = merge(var.common_labels, {
      "name"                          = var.namespace
      "app.kubernetes.io/component"   = "namespace"
      "app.kubernetes.io/environment" = var.environment
    })
    
    annotations = var.common_annotations
  }
}

# Create service account for the application
resource "kubernetes_service_account" "app" {
  metadata {
    name      = "${var.environment}-app-sa"
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "service-account"
      "app.kubernetes.io/name"      = "app"
    })
    
    annotations = var.common_annotations
  }
  
  automount_service_account_token = true
}

# Create cluster role for the service account with minimal permissions
# Create a role with minimal permissions
resource "kubernetes_role" "app_role" {
  count = var.enable_rbac ? 1 : 0
  
  metadata {
    namespace = kubernetes_namespace.main.metadata[0].name
    name      = "${var.project_name}-app-role"
    labels    = var.common_labels
  }

  # SECURITY ISSUE 1: Overly permissive RBAC - allows access to all secrets and pods
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "delete"]
  }
  
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "delete"]
  }
  
  # Additional overly broad permissions
  rule {
    api_groups = [""]
    resources  = ["*"]
    verbs      = ["get", "list"]
  }
}

# Bind the cluster role to the service account
resource "kubernetes_cluster_role_binding" "app" {
  metadata {
    name = "${var.environment}-app-binding"
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "cluster-role-binding"
    })
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.app.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.app.metadata[0].name
    namespace = kubernetes_namespace.app.metadata[0].name
  }
}

# Create network policy for basic traffic isolation
resource "kubernetes_network_policy" "default_deny" {
  count = var.enable_network_policies ? 1 : 0
  
  metadata {
    name      = "default-deny-all"
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "network-policy"
      "policy.type"                 = "deny-all"
    })
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

# Allow communication within the namespace
resource "kubernetes_network_policy" "allow_same_namespace" {
  count = var.enable_network_policies ? 1 : 0
  
  metadata {
    name      = "allow-same-namespace"
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "network-policy"
      "policy.type"                 = "allow-internal"
    })
  }

  spec {
    pod_selector {}
    
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.app.metadata[0].name
          }
        }
      }
    }
    
    egress {
      to {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.app.metadata[0].name
          }
        }
      }
    }
    
    # Allow DNS resolution
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
    
    policy_types = ["Ingress", "Egress"]
  }
}

# Create resource quota for the namespace
resource "kubernetes_resource_quota" "app" {
  metadata {
    name      = "${var.environment}-quota"
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "resource-quota"
    })
  }

  spec {
    hard = {
      "requests.cpu"    = var.resource_limits.cpu_requests
      "requests.memory" = var.resource_limits.memory_requests
      "limits.cpu"      = var.resource_limits.cpu_limits
      "limits.memory"   = var.resource_limits.memory_limits
      "persistentvolumeclaims" = var.resource_limits.pvc_count
      "services"        = var.resource_limits.service_count
      "pods"           = var.resource_limits.pod_count
    }
  }
}

# Create limit range for default resource constraints
resource "kubernetes_limit_range" "app" {
  metadata {
    name      = "${var.environment}-limits"
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "limit-range"
    })
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = var.default_resources.limits.cpu
        memory = var.default_resources.limits.memory
      }
      default_request = {
        cpu    = var.default_resources.requests.cpu
        memory = var.default_resources.requests.memory
      }
    }
    
    limit {
      type = "PersistentVolumeClaim"
      min = {
        storage = "1Gi"
      }
      max = {
        storage = "100Gi"
      }
    }
  }
}

# Create config map for common application configuration
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.environment}-app-config"
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "config"
    })
    
    annotations = var.common_annotations
  }

  data = {
    environment      = var.environment
    namespace        = kubernetes_namespace.app.metadata[0].name
    project_name     = var.project_name
    domain_name      = var.domain_name
    cluster_type     = var.cluster_type
    log_level        = var.log_level
    enable_debug     = var.enable_debug
  }
}
