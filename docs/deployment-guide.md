# Deployment Guide

This guide provides detailed instructions for deploying the Terraform Kubernetes demo project across different environments and platforms.

## 🎯 Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | >= 1.5 | Infrastructure provisioning |
| kubectl | >= 1.24 | Kubernetes cluster interaction |
| Helm | >= 3.0 | Package management |
| Docker | >= 20.0 | Container runtime (for local clusters) |

### Kubernetes Cluster Options

#### 🏠 Local Development

**Option 1: Docker Desktop**
```bash
# Enable Kubernetes in Docker Desktop settings
# Use cluster type: "docker-desktop"
```

**Option 2: microk8s (Ubuntu/Linux)**
```bash
# Install microk8s
sudo snap install microk8s --classic

# Enable required addons
microk8s enable dns storage ingress metallb

# Set up kubectl access
microk8s kubectl config view --raw > ~/.kube/config
```

**Option 3: kind (Kubernetes in Docker)**
```bash
# Install kind
go install sigs.k8s.io/kind@latest

# Create cluster
kind create cluster --config=kind-config.yaml
```

#### ☁️ Cloud Providers

**Google Cloud (GKE)**
```bash
# Create cluster
gcloud container clusters create demo-cluster \
  --num-nodes=3 \
  --machine-type=e2-standard-2 \
  --zone=us-central1-a

# Get credentials
gcloud container clusters get-credentials demo-cluster --zone=us-central1-a
```

**Amazon Web Services (EKS)**
```bash
# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Create cluster
eksctl create cluster --name demo-cluster --nodes 3 --region us-west-2
```

**Microsoft Azure (AKS)**
```bash
# Create resource group
az group create --name demo-rg --location eastus

# Create cluster
az aks create --resource-group demo-rg --name demo-cluster --node-count 3 --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group demo-rg --name demo-cluster
```

## 🚀 Deployment Steps

### Step 1: Environment Preparation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd terraform-k8s-demo
   ```

2. **Verify cluster access**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

3. **Choose your environment**
   ```bash
   # For staging
   cd environments/staging
   
   # For production
   cd environments/production
   ```

### Step 2: Configuration

1. **Copy configuration template**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit configuration** (Critical Step!)
   ```bash
   vim terraform.tfvars
   ```

   **🔒 Security Note**: Change all default passwords!
   ```hcl
   # CHANGE THESE PASSWORDS!
   postgresql_password = "your-secure-postgres-password"
   database_password = "your-secure-db-password"
   redis_password = "your-secure-redis-password"
   grafana_admin_password = "your-secure-grafana-password"
   argocd_admin_password = "your-secure-argocd-password"
   ```

3. **Configure for your cluster type**
   ```hcl
   # For local development
   cluster_type = "microk8s"  # or "docker-desktop", "kind"
   enable_letsencrypt = false
   
   # For cloud deployment
   cluster_type = "gke"  # or "eks", "aks"
   enable_letsencrypt = true
   domain_name = "your-domain.com"
   letsencrypt_email = "admin@your-domain.com"
   ```

### Step 3: Terraform Deployment

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Validate configuration**
   ```bash
   terraform validate
   terraform fmt
   ```

3. **Plan deployment**
   ```bash
   terraform plan -out=tfplan
   ```

4. **Review the plan carefully**
   - Check resource counts
   - Verify configurations
   - Ensure no unexpected changes

5. **Apply configuration**
   ```bash
   # Apply with confirmation
   terraform apply tfplan
   
   # Or apply interactively
   terraform apply
   ```

### Step 4: Verification

1. **Check deployment status**
   ```bash
   # View all resources
   kubectl get all -n staging  # or production
   
   # Check pod status
   kubectl get pods -n staging -w
   
   # View services
   kubectl get svc -n staging
   ```

2. **Get connection information**
   ```bash
   terraform output connection_info
   ```

3. **Access services locally** (for local clusters)
   ```bash
   # Nginx application
   kubectl port-forward -n staging svc/nginx-service 8080:80
   # Access: http://localhost:8080
   
   # Grafana dashboard
   kubectl port-forward -n staging svc/grafana 3000:80
   # Access: http://localhost:3000
   
   # ArgoCD (if enabled)
   kubectl port-forward -n staging svc/argocd-server 8081:80
   # Access: http://localhost:8081
   ```

## 📋 Deployment Configurations

### Staging Environment

**Purpose**: Development, testing, and validation
```hcl
# environments/staging/terraform.tfvars
environment = "staging"
cluster_type = "microk8s"

# Minimal resources
postgresql_config = {
  storage_size = "5Gi"
  architecture = "standalone"
}

# Self-signed certificates
enable_letsencrypt = false
enable_cert_manager = true

# Optional components for testing
enable_topaz = false
enable_tracing = false
```

### Production Environment

**Purpose**: Live workloads with high availability
```hcl
# environments/production/terraform.tfvars
environment = "production"
cluster_type = "gke"  # or your cloud provider

# Production resources
postgresql_config = {
  storage_size = "50Gi"
  architecture = "replication"
}

# Production TLS
enable_letsencrypt = true
domain_name = "prod.yourcompany.com"

# Full feature set
enable_topaz = true
enable_tracing = true
enable_monitoring = true
```

## 🔧 Customization Examples

### Minimal Deployment

For learning or resource-constrained environments:
```hcl
# Disable optional components
enable_istio = false
enable_gitops = false
enable_topaz = false
enable_monitoring = false

# Enable only essential services
enable_cert_manager = true
postgresql_config = {
  storage_size = "1Gi"
}
```

### Full-Featured Deployment

For comprehensive demonstration:
```hcl
# Enable all features
enable_monitoring = true
enable_istio = true
enable_gitops = true
enable_topaz = true
enable_cert_manager = true
enable_letsencrypt = true
enable_tracing = true
enable_network_policies = true
```

### Multi-Region Setup

For high availability across regions:
```hcl
# Configure for multi-region
node_selector = {
  "topology.kubernetes.io/region" = "us-west1"
}

tolerations = [
  {
    key = "multi-region"
    operator = "Equal"
    value = "true"
    effect = "NoSchedule"
  }
]
```

## 🚨 Troubleshooting Common Issues

### Pod Pending State

**Problem**: Pods stuck in Pending state
```bash
kubectl describe pod <pod-name> -n staging
```

**Common Solutions**:
- **Insufficient resources**: Increase cluster resources or reduce requests
- **Storage issues**: Check storage class availability
- **Node affinity**: Verify node selectors and tolerations

### Service Mesh Issues

**Problem**: Istio injection not working
```bash
# Check namespace labels
kubectl get namespace staging --show-labels

# Enable Istio injection
kubectl label namespace staging istio-injection=enabled
```

### Certificate Issues

**Problem**: TLS certificates not issuing
```bash
# Check cert-manager status
kubectl get certificaterequests -n staging
kubectl describe certificate <cert-name> -n staging

# Check Let's Encrypt rate limits
kubectl logs -n cert-manager deployment/cert-manager
```

### Database Connection Issues

**Problem**: Applications can't connect to databases
```bash
# Check service DNS resolution
kubectl run debug --image=busybox -n staging --rm -it -- nslookup postgresql-service

# Test database connectivity
kubectl run debug --image=postgres:13 -n staging --rm -it -- psql -h postgresql-service -U appuser
```

## 📊 Monitoring Deployment

### Health Checks

```bash
# Check all pod health
kubectl get pods -n staging --field-selector=status.phase!=Running

# View resource usage
kubectl top pods -n staging
kubectl top nodes

# Check persistent volumes
kubectl get pv,pvc -n staging
```

### Application Metrics

```bash
# Port forward to Grafana
kubectl port-forward -n staging svc/grafana 3000:80

# Access Prometheus directly
kubectl port-forward -n staging svc/prometheus-server 9090:80
```

### Log Analysis

```bash
# View application logs
kubectl logs -f deployment/nginx-deployment -n staging

# View all pods logs
kubectl logs -f -l app=nginx -n staging

# Check system events
kubectl get events -n staging --sort-by='.lastTimestamp'
```

## 🔄 Updating and Maintenance

### Updating Terraform Configuration

1. **Make changes to configuration files**
2. **Plan the update**
   ```bash
   terraform plan
   ```
3. **Apply changes**
   ```bash
   terraform apply
   ```

### Upgrading Components

```bash
# Update Helm charts
helm repo update

# Upgrade specific releases
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n staging
```

### Backup Procedures

```bash
# Backup Terraform state
terraform state pull > backup-$(date +%Y%m%d).tfstate

# Backup Kubernetes resources
kubectl get all,secrets,cm,pv,pvc -n staging -o yaml > backup-k8s-$(date +%Y%m%d).yaml
```

## 🏁 Next Steps

After successful deployment:

1. **Explore the services**: Use port-forwarding to access each component
2. **Review monitoring**: Set up dashboards and alerts in Grafana
3. **Configure GitOps**: Set up ArgoCD with your application repositories
4. **Security hardening**: Review RBAC policies and network policies
5. **Performance tuning**: Adjust resource limits based on usage

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Helm Charts](https://helm.sh/docs)
- [Istio Documentation](https://istio.io/docs)
- [Prometheus Monitoring](https://prometheus.io/docs)

---

**Need Help?** Check the [troubleshooting guide](troubleshooting.md) or open an issue with your specific deployment details.
