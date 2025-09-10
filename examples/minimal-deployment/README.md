# Minimal Deployment Example

This example demonstrates the simplest possible deployment using the Terraform Kubernetes modules. It's perfect for learning, testing, or resource-constrained environments.

## What's Included

- **Kubernetes Base**: Namespace, service account, basic RBAC
- **PostgreSQL**: Single database instance
- **Nginx Application**: Simple web server

## What's Excluded

- Service mesh (Istio)
- Monitoring (Prometheus/Grafana)
- Certificate management
- GitOps (ArgoCD)
- Additional databases (Redis, ClickHouse, MinIO)
- Network policies
- Auto-scaling

## Quick Start

```bash
# Navigate to the example
cd examples/minimal-deployment

# Initialize and apply
terraform init
terraform apply

# Get connection instructions
terraform output next_steps
```

## Access the Application

```bash
# Port forward to the nginx service
kubectl port-forward -n minimal svc/nginx-service 8080:80

# Access in browser
open http://localhost:8080
```

## Connect to Database

```bash
# Connect to PostgreSQL
kubectl exec -it -n minimal deployment/postgresql -- psql -U appuser -d appdb
```

## Resource Usage

This minimal deployment uses approximately:
- **CPU**: 300m requests, 1.1 CPU limits
- **Memory**: 384Mi requests, 896Mi limits
- **Storage**: 2Gi for PostgreSQL

Perfect for:
- Docker Desktop (2 CPU, 4GB RAM)
- microk8s on a laptop
- Learning Terraform and Kubernetes basics

## Clean Up

```bash
terraform destroy
```

## Next Steps

After exploring this minimal example:

1. **Try staging environment**: `cd ../../environments/staging`
2. **Enable monitoring**: Set `enable_monitoring = true`
3. **Add service mesh**: Set `enable_istio = true`
4. **Explore modules**: Review individual modules in `../../modules/`
