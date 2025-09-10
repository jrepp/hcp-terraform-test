# modules/data-services/outputs.tf
# Outputs for the data-services module

# PostgreSQL outputs
output "postgresql_service_name" {
  description = "Name of the PostgreSQL service"
  value       = var.enable_postgresql ? "${var.environment}-postgresql" : null
}

output "postgresql_port" {
  description = "PostgreSQL service port"
  value       = var.enable_postgresql ? 5432 : null
}

output "postgresql_database" {
  description = "PostgreSQL database name"
  value       = var.enable_postgresql ? var.postgresql_config.database : null
}

# Redis outputs
output "redis_service_name" {
  description = "Name of the Redis master service"
  value       = var.enable_redis ? "${var.environment}-redis-master" : null
}

output "redis_port" {
  description = "Redis service port"
  value       = var.enable_redis ? 6379 : null
}

# ClickHouse outputs
output "clickhouse_service_name" {
  description = "Name of the ClickHouse service"
  value       = var.enable_clickhouse ? "${var.environment}-clickhouse" : null
}

output "clickhouse_http_port" {
  description = "ClickHouse HTTP port"
  value       = var.enable_clickhouse ? 8123 : null
}

output "clickhouse_tcp_port" {
  description = "ClickHouse TCP port"
  value       = var.enable_clickhouse ? 9000 : null
}

# MinIO outputs
output "minio_service_name" {
  description = "Name of the MinIO service"
  value       = var.enable_minio ? "${var.environment}-minio" : null
}

output "minio_api_port" {
  description = "MinIO API port"
  value       = var.enable_minio ? 9000 : null
}

output "minio_console_port" {
  description = "MinIO console port"
  value       = var.enable_minio ? 9001 : null
}

output "minio_buckets" {
  description = "List of created MinIO buckets"
  value       = var.enable_minio ? var.minio_config.default_buckets : []
}

# Secret and ConfigMap outputs
output "database_credentials_secret" {
  description = "Name of the secret containing database credentials"
  value       = kubernetes_secret.database_credentials.metadata[0].name
}

output "database_config_map" {
  description = "Name of the config map containing database configuration"
  value       = kubernetes_config_map.database_config.metadata[0].name
}

# Connection strings for applications
output "connection_info" {
  description = "Database connection information for applications"
  value = {
    postgresql = var.enable_postgresql ? {
      host     = "${var.environment}-postgresql"
      port     = 5432
      database = var.postgresql_config.database
      username = var.postgresql_config.username
      url      = "postgresql://${var.postgresql_config.username}@${var.environment}-postgresql:5432/${var.postgresql_config.database}"
    } : null
    
    redis = var.enable_redis ? {
      host = "${var.environment}-redis-master"
      port = 6379
      url  = "redis://${var.environment}-redis-master:6379"
    } : null
    
    clickhouse = var.enable_clickhouse ? {
      host     = "${var.environment}-clickhouse"
      http_port = 8123
      tcp_port  = 9000
      username  = var.clickhouse_config.username
      http_url  = "http://${var.environment}-clickhouse:8123"
    } : null
    
    minio = var.enable_minio ? {
      endpoint    = "${var.environment}-minio:9000"
      console_url = "${var.environment}-minio:9001"
      buckets     = var.minio_config.default_buckets
    } : null
  }
  sensitive = true
}

# Helm release information
output "helm_releases" {
  description = "Information about deployed Helm releases"
  value = {
    postgresql = var.enable_postgresql ? {
      name      = helm_release.postgresql[0].name
      chart     = helm_release.postgresql[0].chart
      version   = helm_release.postgresql[0].version
      namespace = helm_release.postgresql[0].namespace
      status    = helm_release.postgresql[0].status
    } : null
    
    redis = var.enable_redis ? {
      name      = helm_release.redis[0].name
      chart     = helm_release.redis[0].chart
      version   = helm_release.redis[0].version
      namespace = helm_release.redis[0].namespace
      status    = helm_release.redis[0].status
    } : null
    
    clickhouse = var.enable_clickhouse ? {
      name      = helm_release.clickhouse[0].name
      chart     = helm_release.clickhouse[0].chart
      version   = helm_release.clickhouse[0].version
      namespace = helm_release.clickhouse[0].namespace
      status    = helm_release.clickhouse[0].status
    } : null
    
    minio = var.enable_minio ? {
      name      = helm_release.minio[0].name
      chart     = helm_release.minio[0].chart
      version   = helm_release.minio[0].version
      namespace = helm_release.minio[0].namespace
      status    = helm_release.minio[0].status
    } : null
  }
}
