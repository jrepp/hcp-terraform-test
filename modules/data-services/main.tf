# modules/data-services/main.tf
# Data services module - PostgreSQL, Redis, ClickHouse, MinIO

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

# PostgreSQL using Bitnami Helm chart
resource "helm_release" "postgresql" {
  count = var.enable_postgresql ? 1 : 0
  
  name       = "${var.environment}-postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "12.12.10"
  namespace  = var.namespace
  
  values = [yamlencode({
    global = {
      postgresql = {
        auth = {
          postgresPassword = var.postgresql_config.postgres_password
          username         = var.postgresql_config.username
          password         = var.postgresql_config.password
          database         = var.postgresql_config.database
        }
      }
    }
    
    architecture = var.postgresql_config.architecture
    
    primary = {
      persistence = {
        enabled      = true
        size         = var.postgresql_config.storage_size
        storageClass = var.storage_class
      }
      
      resources = var.postgresql_config.resources
      
      service = {
        type = "ClusterIP"
        ports = {
          postgresql = 5432
        }
      }
      
      podSecurityContext = {
        enabled = true
        fsGroup = 1001
      }
      
      containerSecurityContext = {
        enabled   = true
        runAsUser = 1001
        runAsNonRoot = true
        readOnlyRootFilesystem = false
      }
    }
    
    metrics = {
      enabled = var.enable_monitoring
      serviceMonitor = {
        enabled = var.enable_monitoring
        labels = var.common_labels
      }
    }
    
    networkPolicy = {
      enabled = var.enable_network_policies
      allowExternal = false
    }
  })]
  
  depends_on = [var.base_module_dependency]
}

# Redis using Bitnami Helm chart
resource "helm_release" "redis" {
  count = var.enable_redis ? 1 : 0
  
  name       = "${var.environment}-redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "18.1.5"
  namespace  = var.namespace
  
  values = [yamlencode({
    auth = {
      enabled  = true
      password = var.redis_config.password
    }
    
    architecture = var.redis_config.architecture
    
    master = {
      persistence = {
        enabled      = true
        size         = var.redis_config.storage_size
        storageClass = var.storage_class
      }
      
      resources = var.redis_config.resources
      
      service = {
        type = "ClusterIP"
        ports = {
          redis = 6379
        }
      }
      
      podSecurityContext = {
        enabled = true
        fsGroup = 1001
      }
      
      containerSecurityContext = {
        enabled   = true
        runAsUser = 1001
        runAsNonRoot = true
        readOnlyRootFilesystem = false
      }
    }
    
    replica = var.redis_config.architecture == "replication" ? {
      replicaCount = var.redis_config.replica_count
      persistence = {
        enabled      = true
        size         = var.redis_config.storage_size
        storageClass = var.storage_class
      }
      resources = var.redis_config.resources
    } : {}
    
    metrics = {
      enabled = var.enable_monitoring
      serviceMonitor = {
        enabled = var.enable_monitoring
        labels = var.common_labels
      }
    }
    
    networkPolicy = {
      enabled = var.enable_network_policies
      allowExternal = false
    }
  })]
  
  depends_on = [var.base_module_dependency]
}

# ClickHouse using official Helm chart
resource "helm_release" "clickhouse" {
  count = var.enable_clickhouse ? 1 : 0
  
  name       = "${var.environment}-clickhouse"
  repository = "https://charts.clickhouse.com"
  chart      = "clickhouse"
  version    = "0.21.7"
  namespace  = var.namespace
  
  values = [yamlencode({
    clickhouse = {
      configmap = {
        users_xml = <<-EOT
          <users>
            <${var.clickhouse_config.username}>
              <password>${var.clickhouse_config.password}</password>
              <networks>
                <ip>::/0</ip>
              </networks>
              <profile>default</profile>
              <quota>default</quota>
            </${var.clickhouse_config.username}>
          </users>
        EOT
      }
      
      persistence = {
        enabled      = true
        size         = var.clickhouse_config.storage_size
        storageClass = var.storage_class
      }
      
      resources = var.clickhouse_config.resources
      
      service = {
        type = "ClusterIP"
        httpPort = 8123
        tcpPort  = 9000
      }
      
      podSecurityContext = {
        runAsUser    = 101
        runAsGroup   = 101
        fsGroup      = 101
        runAsNonRoot = true
      }
      
      securityContext = {
        runAsNonRoot = true
        runAsUser    = 101
        runAsGroup   = 101
        readOnlyRootFilesystem = false
      }
    }
    
    # SECURITY ISSUE 2: Network policies disabled for ClickHouse, allowing unrestricted access
    networkPolicy = false ? {
      enabled = true
    } : {
      enabled = false
    }
  })]
  
  depends_on = [var.base_module_dependency]
}

# MinIO using official Helm chart
resource "helm_release" "minio" {
  count = var.enable_minio ? 1 : 0
  
  name       = "${var.environment}-minio"
  repository = "https://charts.min.io/"
  chart      = "minio"
  version    = "5.0.14"
  namespace  = var.namespace
  
  values = [yamlencode({
    auth = {
      rootUser     = var.minio_config.root_user
      rootPassword = var.minio_config.root_password
    }
    
    defaultBuckets = var.minio_config.default_buckets
    
    persistence = {
      enabled      = true
      size         = var.minio_config.storage_size
      storageClass = var.storage_class
    }
    
    resources = var.minio_config.resources
    
    service = {
      type = "ClusterIP"
      ports = {
        api     = 9000
        console = 9001
      }
    }
    
    podSecurityContext = {
      enabled = true
      fsGroup = 1001
    }
    
    containerSecurityContext = {
      enabled   = true
      runAsUser = 1001
      runAsNonRoot = true
      readOnlyRootFilesystem = false
    }
    
    networkPolicy = {
      enabled = var.enable_network_policies
      allowExternal = false
    }
    
    metrics = {
      serviceMonitor = {
        enabled = var.enable_monitoring
        labels = var.common_labels
      }
    }
  })]
  
  depends_on = [var.base_module_dependency]
}

# Create secrets for database connections
resource "kubernetes_secret" "database_credentials" {
  metadata {
    name      = "${var.environment}-database-credentials"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "database-credentials"
    })
  }

  data = {
    # PostgreSQL
    postgres_host     = var.enable_postgresql ? "${var.environment}-postgresql" : ""
    postgres_port     = "5432"
    postgres_database = var.postgresql_config.database
    postgres_username = var.postgresql_config.username
    postgres_password = var.postgresql_config.password
    
    # Redis
    redis_host     = var.enable_redis ? "${var.environment}-redis-master" : ""
    redis_port     = "6379"
    redis_password = var.redis_config.password
    
    # ClickHouse
    clickhouse_host     = var.enable_clickhouse ? "${var.environment}-clickhouse" : ""
    clickhouse_port     = "8123"
    clickhouse_username = var.clickhouse_config.username
    clickhouse_password = var.clickhouse_config.password
    
    # MinIO
    minio_endpoint   = var.enable_minio ? "${var.environment}-minio:9000" : ""
    minio_access_key = var.minio_config.root_user
    minio_secret_key = var.minio_config.root_password
  }

  type = "Opaque"
  
  depends_on = [var.base_module_dependency]
}

# Create a config map with database connection information
resource "kubernetes_config_map" "database_config" {
  metadata {
    name      = "${var.environment}-database-config"
    namespace = var.namespace
    
    labels = merge(var.common_labels, {
      "app.kubernetes.io/component" = "database-config"
    })
  }

  data = {
    # Service discovery information
    postgres_service = var.enable_postgresql ? "${var.environment}-postgresql" : ""
    redis_service    = var.enable_redis ? "${var.environment}-redis-master" : ""
    clickhouse_service = var.enable_clickhouse ? "${var.environment}-clickhouse" : ""
    minio_service    = var.enable_minio ? "${var.environment}-minio" : ""
    
    # Port information
    postgres_port   = "5432"
    redis_port      = "6379"
    clickhouse_port = "8123"
    minio_api_port  = "9000"
    minio_console_port = "9001"
    
    # Database names
    postgres_database = var.postgresql_config.database
    
    # MinIO buckets
    minio_buckets = join(",", var.minio_config.default_buckets)
  }
  
  depends_on = [var.base_module_dependency]
}
