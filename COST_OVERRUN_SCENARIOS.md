# Cost Overrun Scenarios - Branch: cost-overrun-scenarios

This branch contains **intentional cost overruns** for testing and educational purposes. These issues simulate common misconfigurations that can lead to unexpected cloud infrastructure costs.

## ⚠️ **WARNING: EXPENSIVE CONFIGURATIONS**

This branch contains deliberate cost overruns that could result in **significant cloud bills** if deployed. Use only in cost-controlled environments.

## 💰 Cost Issues Introduced

### Issue 1: Excessive Database Resource Allocation
**Location**: `modules/data-services/main.tf` (PostgreSQL configuration)
**Type**: Resource Over-Provisioning

**Problem**: PostgreSQL configured with enterprise-grade resources for simple workloads:
- **CPU Requests**: 4000m (4 full CPUs) vs typical 200m
- **Memory Requests**: 16Gi vs typical 512Mi
- **CPU Limits**: 8000m (8 full CPUs) vs typical 1000m  
- **Memory Limits**: 32Gi vs typical 2Gi

**Cost Impact**: 
- 20x higher compute costs than necessary
- Forces larger node sizes in cloud environments
- Wastes resources that could serve other workloads

**Monthly Cost Estimate**:
- **AWS EKS**: Additional $500-800/month per database instance
- **GKE**: Additional $400-700/month per database instance
- **Local**: Requires expensive hardware/VMs

### Issue 2: Runaway Redis Replication
**Location**: `modules/data-services/main.tf` (Redis configuration)
**Type**: Excessive Replica Count

**Problem**: Redis configured with 15 replicas instead of typical 2-3:
- **Replica Count**: 15 pods vs typical 2-3
- Each replica consumes same resources as master
- No benefit for most workloads beyond 3 replicas

**Cost Impact**:
- 5x higher Redis infrastructure costs
- 15 persistent volumes instead of 3
- Network traffic amplification

**Monthly Cost Estimate**:
- **Additional Storage**: 12 extra persistent volumes
- **Additional Compute**: 12 extra Redis instances
- **Cost Multiplier**: 5x normal Redis costs

### Issue 3: Aggressive Auto-Scaling Configuration
**Location**: `modules/nginx-app/main.tf` (HPA configuration)
**Type**: Auto-Scaling Misconfiguration

**Problem**: Horizontal Pod Autoscaler with aggressive scaling parameters:
- **Min Replicas**: 50 (always running) vs typical 1-3
- **Max Replicas**: 500 vs typical 10-20
- **CPU Threshold**: 5% vs typical 70%
- **Memory Threshold**: 10% vs typical 80%

**Cost Impact**:
- Minimum 50 pods always consuming resources
- Scales up at slightest load (5% CPU usage)
- Can quickly reach 500 pods under normal load

**Cost Scenarios**:
- **Idle State**: 50 nginx pods running 24/7
- **Light Load**: Could scale to 100-200 pods
- **Normal Load**: Could hit 500 pod maximum

**Monthly Cost Estimate**:
- **Baseline**: 50 pods × $10/pod = $500/month minimum
- **Under Load**: 200+ pods × $10/pod = $2000+/month

### Issue 4: Premium Storage for Non-Production
**Location**: `environments/staging/terraform.tfvars.example`
**Type**: Storage Class and Size Misconfiguration

**Problem**: Using expensive storage configurations for staging:
- **Storage Class**: `fast-ssd-premium` instead of `standard`
- **PostgreSQL**: 1TB vs typical 5-10GB for staging
- **Redis**: 500GB vs typical 1-2GB
- **ClickHouse**: 2TB vs typical 50-100GB
- **MinIO**: 5TB vs typical 100GB
- **Prometheus**: 1TB vs typical 20-50GB

**Cost Impact**:
- Premium SSD costs 3-10x more than standard storage
- Excessive sizes for staging environment needs
- 8.6TB total storage allocation for staging

**Monthly Cost Estimate**:
- **Standard Storage**: 8.6TB × $0.10/GB = $860/month
- **Premium SSD**: 8.6TB × $0.30-0.50/GB = $2580-4300/month

### Issue 5: Excessive Monitoring Retention
**Location**: `modules/observability/main.tf` (Prometheus configuration)
**Type**: Monitoring Storage Overallocation

**Problem**: Prometheus configured with enterprise-grade retention:
- **Retention Period**: 2 years vs typical 15-30 days
- **Storage Size**: 10TB vs typical 50-100GB
- High-frequency metrics stored for years

**Cost Impact**:
- 24x longer retention than necessary
- 100x more storage than typical requirements
- Exponential growth of historical data

**Monthly Cost Estimate**:
- **Storage Cost**: 10TB × $0.10-0.30/GB = $1000-3000/month
- **I/O Costs**: High read/write operations on large dataset
- **Backup Costs**: If automated backups enabled

## 🔍 Detection Methods

### Cost Monitoring Tools

```bash
# Kubernetes resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check resource requests/limits
kubectl describe nodes | grep -A 5 "Allocated resources"

# Storage usage
kubectl get pv,pvc --all-namespaces
kubectl get pvc -o custom-columns=NAME:.metadata.name,SIZE:.spec.resources.requests.storage

# HPA status
kubectl get hpa --all-namespaces
kubectl describe hpa --all-namespaces
```

### Cloud Cost Analysis

```bash
# AWS Cost Explorer API
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-02-01 --granularity MONTHLY --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE

# GCP Billing API
gcloud billing budgets list --billing-account=BILLING_ACCOUNT_ID

# Azure Cost Management
az consumption usage list --start-date 2024-01-01 --end-date 2024-02-01
```

### Terraform Cost Estimation

```bash
# Infracost analysis
infracost breakdown --path .
infracost diff --path .

# Terraform plan with resource analysis
terraform plan -out=tfplan
terraform show -json tfplan | jq '.resource_changes[].change.after'
```

## 📊 Cost Comparison Table

| Component | Normal Configuration | Cost Overrun Config | Cost Multiplier |
|-----------|---------------------|-------------------|-----------------|
| PostgreSQL CPU | 200m | 4000m | 20x |
| PostgreSQL Memory | 512Mi | 16Gi | 32x |
| Redis Replicas | 3 | 15 | 5x |
| Nginx Min Pods | 1 | 50 | 50x |
| Nginx Max Pods | 10 | 500 | 50x |
| Storage Class | Standard | Premium SSD | 3-10x |
| Storage Size | 50GB total | 8.6TB total | 172x |
| Prometheus Retention | 30 days | 2 years | 24x |

**Total Cost Impact**: 10-100x higher than reasonable configuration

## 🛠️ Cost Optimization Fixes

### Fix 1: Right-Size Database Resources
```hcl
# PostgreSQL - appropriate for staging
resources = {
  requests = {
    cpu    = "200m"
    memory = "512Mi"
  }
  limits = {
    cpu    = "1000m"
    memory = "2Gi"
  }
}
```

### Fix 2: Reasonable Redis Replication
```hcl
# Redis - staging with 1 replica, production with 2-3
replicaCount = var.environment == "staging" ? 1 : 3
```

### Fix 3: Sensible Auto-Scaling
```hcl
# HPA - conservative scaling
min_replicas = 1
max_replicas = 10
target_cpu_utilization = 70
target_memory_utilization = 80
```

### Fix 4: Appropriate Storage Configuration
```hcl
# Staging storage - standard class, reasonable sizes
storage_class = "standard"
postgresql_storage_size = "10Gi"
redis_storage_size = "2Gi"
prometheus_storage_size = "20Gi"
```

### Fix 5: Reasonable Monitoring Retention
```hcl
# Prometheus - 30 days retention for staging
retention = "30d"
storage_size = "50Gi"
```

## 🚨 Cost Alerts and Monitoring

### Set Up Budget Alerts

```yaml
# Example AWS Budget
aws budgets create-budget --account-id 123456789012 --budget '{
  "BudgetName": "kubernetes-monthly-budget",
  "BudgetLimit": {
    "Amount": "100",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}'
```

### Resource Quotas
```yaml
# Prevent runaway resource usage
apiVersion: v1
kind: ResourceQuota
metadata:
  name: cost-control-quota
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    persistentvolumeclaims: "10"
    count/pods: "50"
```

### Pod Disruption Budgets
```yaml
# Prevent excessive replica counts
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: cost-control-pdb
spec:
  maxUnavailable: 50%
  selector:
    matchLabels:
      app: nginx
```

## 🎯 Testing Scenarios

### Scenario 1: Deploy and Monitor Costs
1. Deploy to cost-controlled cloud environment
2. Monitor resource usage and costs for 24 hours
3. Compare with normal branch deployment
4. Calculate cost difference

### Scenario 2: Load Testing Impact
1. Generate moderate load on nginx application
2. Observe auto-scaling behavior (should scale aggressively)
3. Monitor pod count and resource consumption
4. Calculate cost during load test

### Scenario 3: Storage Growth Analysis
1. Deploy with large storage allocations
2. Monitor actual vs allocated storage usage
3. Calculate waste percentage
4. Project long-term storage costs

## 📈 Cost Projection Models

### Linear Growth Model
```
Monthly Cost = Base Infrastructure + (Resource Usage × Time × Rate)

Example:
- Base: $100/month
- Overrun Multiplier: 50x
- Projected Cost: $5,000/month
```

### Auto-Scaling Cost Model
```
Hourly Cost = Min Replicas × Base Cost + (Scale Events × Peak Cost)

Example:
- Min Cost: 50 pods × $0.10/hour = $5/hour = $3,600/month
- Peak Cost: 500 pods × $0.10/hour = $50/hour during spikes
```

## 🔄 Branch Management

```bash
# Switch to cost overrun branch
git checkout cost-overrun-scenarios

# Compare costs with main branch
git diff main cost-overrun-scenarios

# Test cost estimation
infracost diff --path . --compare-to main

# Return to cost-optimized main branch
git checkout main
```

## 📚 Learning Objectives

This branch teaches:

1. **Cost Awareness**: Understanding how configurations affect costs
2. **Resource Planning**: Right-sizing resources for workloads
3. **Monitoring Setup**: Implementing cost monitoring and alerts
4. **Optimization Techniques**: Identifying and fixing cost issues
5. **Budget Management**: Setting up cost controls and limits

## 💡 Key Takeaways

- **Small Configuration Changes** can have massive cost impacts
- **Default Values** in examples might not be cost-optimized
- **Auto-scaling** needs careful tuning to avoid runaway costs
- **Storage Choices** significantly impact long-term expenses
- **Monitoring Retention** should match actual business needs
- **Cost Governance** should be built into deployment pipelines

---

**Remember**: These cost overruns are intentional for learning. Always implement cost controls and monitoring in real deployments!
