# Terraform Kubernetes Demo Project

A comprehensive Terraform example project demonstrating multi-environment Kubernetes deployments with modern cloud-native technologies.

## 🎯 Project Overview

This project provides a **minimally complete** yet **production-ready** Terraform configuration for deploying cloud-native applications on Kubernetes. It demonstrates best practices for infrastructure as code, modular design, and security-first approach.

### 🌟 Key Features

- **Multi-Environment Support**: Staging and Production environments with environment-specific configurations
- **Modular Architecture**: Reusable Terraform modules for different infrastructure components
- **Security First**: Network policies, RBAC, TLS encryption, and authorization services
- **Observability**: Comprehensive monitoring with Prometheus, Grafana, and distributed tracing
- **GitOps Ready**: ArgoCD integration for continuous deployment
- **Cloud Native**: Service mesh (Istio), automatic TLS (cert-manager), object storage (MinIO)
- **Data Services**: PostgreSQL, Redis, ClickHouse for various data storage needs

### 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
├─────────────────────────────────────────────────────────────┤
│  Nginx App  │  Grafana  │  ArgoCD  │  MinIO Console        │
├─────────────────────────────────────────────────────────────┤
│                   Service Mesh (Istio)                     │
├─────────────────────────────────────────────────────────────┤
│  Security     │  Monitoring   │  Data Services             │
│  - Topaz.sh   │  - Prometheus │  - PostgreSQL              │
│  - Cert-Mgr   │  - Grafana    │  - Redis                   │
│  - Network    │  - AlertMgr   │  - ClickHouse              │
│    Policies   │               │  - MinIO                   │
├─────────────────────────────────────────────────────────────┤
│                Kubernetes Base Infrastructure               │
│  - Namespaces - RBAC - Resource Quotas - Network Policies  │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Terraform** >= 1.5
- **Kubernetes cluster** (microk8s, docker-desktop, kind, or cloud provider)
- **kubectl** configured with cluster access
- **Helm** >= 3.0

### 1. Clone and Setup

```bash
git clone <repository-url>
cd terraform-k8s-demo

# Choose your environment
cd environments/staging  # or environments/production
```

### 2. Configure Variables

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration (IMPORTANT: Change default passwords!)
vim terraform.tfvars
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply configuration
terraform apply
```

### 4. Access Services

After deployment, access your services:

```bash
# Get connection information
terraform output connection_info

# Port forward for local testing (if needed)
kubectl port-forward -n staging svc/nginx-service 8080:80
kubectl port-forward -n staging svc/grafana 3000:80
```

## 📁 Project Structure

```
.
├── README.md                    # This file
├── docs/                        # Documentation
│   ├── deployment-guide.md      # Detailed deployment instructions
│   ├── troubleshooting.md       # Common issues and solutions
│   └── module-reference.md      # Module documentation
├── shared/                      # Shared configuration
│   ├── locals.tf               # Common values and defaults
│   └── variables.tf            # Global variable definitions
├── modules/                     # Reusable Terraform modules
│   ├── kubernetes-base/        # Base Kubernetes resources
│   ├── data-services/          # Database and storage services
│   ├── observability/          # Monitoring and alerting
│   ├── security/              # Authorization and certificates
│   ├── networking/            # Service mesh and ingress
│   ├── nginx-app/             # Sample application
│   ├── cert-manager/          # TLS certificate management
│   └── gitops/                # ArgoCD for continuous deployment
├── environments/               # Environment-specific configurations
│   ├── staging/               # Staging environment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   └── production/            # Production environment
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
└── examples/                   # Usage examples
    └── basic-deployment/       # Simple deployment example
```

## 🧩 Modules Overview

### Core Infrastructure
- **`kubernetes-base`**: Namespaces, RBAC, network policies, resource quotas
- **`data-services`**: PostgreSQL, Redis, ClickHouse, MinIO with Helm charts
- **`observability`**: Prometheus, Grafana, AlertManager monitoring stack

### Security & Networking
- **`security`**: Topaz.sh (OpenFGA) authorization service
- **`networking`**: Istio service mesh with mTLS and traffic policies
- **`cert-manager`**: Automated TLS certificate management

### Applications & Operations
- **`nginx-app`**: Sample web application with HPA and monitoring
- **`gitops`**: ArgoCD for GitOps-based deployment automation

## 🛠️ Customization

### Environment-Specific Configuration

Each environment (staging/production) can be customized independently:

```hcl
# environments/staging/terraform.tfvars
environment = "staging"
cluster_type = "microk8s"
enable_letsencrypt = false  # Use self-signed certs for staging

# environments/production/terraform.tfvars
environment = "production"
cluster_type = "gke"
enable_letsencrypt = true   # Use Let's Encrypt for production
```

### Feature Flags

Enable/disable components as needed:

```hcl
enable_monitoring = true
enable_istio = true
enable_gitops = false      # Disable ArgoCD if not needed
enable_topaz = false       # Disable authorization service
```

### Resource Scaling

Adjust resources for your workload:

```hcl
# Production-grade resources
postgresql_config = {
  storage_size = "100Gi"
  architecture = "replication"
}

nginx_config = {
  replica_count = 5
  hpa_config = {
    max_replicas = 50
  }
}
```

## 🔐 Security Features

### Network Security
- **Network Policies**: Restrict pod-to-pod communication
- **Service Mesh mTLS**: Automatic encryption between services
- **Ingress TLS**: HTTPS termination with automatic certificates

### Authentication & Authorization
- **RBAC**: Kubernetes role-based access control
- **Service Accounts**: Minimal privilege principle
- **OpenFGA Integration**: Fine-grained authorization with Topaz.sh

### Secrets Management
- **Kubernetes Secrets**: Encrypted storage of sensitive data
- **External Secrets**: Integration ready for external secret stores
- **TLS Certificates**: Automated certificate lifecycle management

## 📊 Monitoring & Observability

### Metrics Collection
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **AlertManager**: Alert routing and notification

### Application Monitoring
- **Custom Dashboards**: Pre-configured for each service
- **Health Checks**: Readiness and liveness probes
- **Service Monitors**: Automatic metrics discovery

### Distributed Tracing
- **Jaeger Integration**: Request tracing across services
- **Istio Tracing**: Automatic trace collection

## 🔄 GitOps Integration

### ArgoCD Setup
- **Multi-Project Support**: Separate projects for different teams
- **RBAC Integration**: Role-based access to applications
- **Auto-Sync Policies**: Automated deployment with controls

### Application Management
- **Declarative Config**: Applications defined as code
- **Progressive Delivery**: Canary deployments and rollbacks
- **Sync Policies**: Automated or manual synchronization

## 🌍 Multi-Cloud Support

Tested and validated on:
- **Local Development**: microk8s, docker-desktop, kind
- **Google Cloud**: GKE with Workload Identity
- **Amazon Web Services**: EKS with IAM roles
- **Microsoft Azure**: AKS with managed identity

## 📖 Documentation

- **[Deployment Guide](docs/deployment-guide.md)**: Step-by-step deployment instructions
- **[Module Reference](docs/module-reference.md)**: Detailed module documentation
- **[Troubleshooting](docs/troubleshooting.md)**: Common issues and solutions

## 🤝 Contributing

This project is designed for learning and demonstration. Key areas for contribution:

1. **Additional Modules**: Create modules for other services
2. **Cloud Providers**: Add provider-specific optimizations
3. **Security Enhancements**: Implement additional security measures
4. **Documentation**: Improve examples and use cases

## 🎓 Learning Objectives

This project helps you learn:

### Terraform Best Practices
- **Module Design**: Creating reusable, composable modules
- **State Management**: Remote state and workspace patterns
- **Variable Management**: Validation, defaults, and documentation

### Kubernetes Patterns
- **Resource Management**: Quotas, limits, and scheduling
- **Security Models**: RBAC, network policies, and pod security
- **Service Discovery**: Internal and external service exposure

### Cloud Native Technologies
- **Service Mesh**: Traffic management and security
- **Observability**: Metrics, logging, and tracing
- **GitOps**: Continuous deployment patterns

### DevOps Practices
- **Infrastructure as Code**: Declarative infrastructure management
- **Environment Promotion**: Consistent deployment across environments
- **Security Integration**: Security as code principles

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the [troubleshooting guide](docs/troubleshooting.md)
2. Review the [module documentation](docs/module-reference.md)
3. Open an issue with detailed information about your environment

---

**Happy Learning! 🚀**

This project represents modern infrastructure practices and serves as a foundation for building production-ready Kubernetes deployments with Terraform.
