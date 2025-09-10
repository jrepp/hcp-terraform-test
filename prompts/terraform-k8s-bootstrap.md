# Terraform Kubernetes Infrastructure Bootstrap Prompt

## 📋 Objective

Create a **minimally complete** Terraform example project that demonstrates multi-environment Kubernetes deployments with modern cloud-native technologies. This project should serve as both a learning platform and production foundation.

## 🎯 Core Requirements

### Infrastructure Components
- **Kubernetes Base**: Persistent Volumes (PVs), Service Accounts, Services, Namespaces, RBAC
- **Web Application**: Nginx deployment with health checks and auto-scaling
- **Object Storage**: MinIO bucket storage with console access
- **Databases**: PostgreSQL, Redis, ClickHouse for various data storage needs
- **Authorization**: Topaz.sh (OpenFGA) for fine-grained access control
- **Service Mesh**: Istio with Envoy proxy for traffic management and security
- **Certificate Management**: cert-manager for automated TLS certificate lifecycle
- **GitOps**: ArgoCD for continuous deployment and application management
- **Monitoring**: Prometheus stack with Grafana dashboards and AlertManager

### Environment Strategy
- **Two Environments**: `staging` and `production` with environment-specific configurations
- **Testability**: Must work on microk8s, Docker Desktop, or similar local Kubernetes
- **Cloud Compatibility**: Should be deployable on GKE, EKS, AKS with minimal changes
- **Resource Scaling**: Different resource profiles for staging vs production

### Architecture Principles
- **Modular Design**: Create reusable Terraform modules for each component
- **Security First**: Implement network policies, RBAC, TLS everywhere
- **Provider Standards**: Use official Terraform providers and Helm charts from standard registries
- **Documentation Focus**: Extensive documentation for learning and onboarding

## 🏗️ Technical Specifications

### Terraform Configuration
```hcl
# Required Terraform version and providers
terraform {
  required_version = ">= 1.5"
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
```

### Project Structure
```
project-root/
├── shared/                     # Shared configuration values
├── modules/                    # Reusable Terraform modules
│   ├── kubernetes-base/       # Base K8s resources
│   ├── data-services/         # Databases and storage
│   ├── observability/         # Monitoring stack
│   ├── security/              # Authorization and TLS
│   ├── networking/            # Service mesh and ingress
│   ├── cert-manager/          # Certificate management
│   ├── nginx-app/             # Sample application
│   └── gitops/                # ArgoCD deployment
├── environments/               # Environment-specific configs
│   ├── staging/               # Development environment
│   └── production/            # Production environment
├── docs/                      # Comprehensive documentation
├── examples/                  # Usage examples
└── prompts/                   # Agent bootstrap prompts
```

### Module Requirements

**Each module must include:**
- `main.tf` - Resource definitions
- `variables.tf` - Input variables with validation
- `outputs.tf` - Resource outputs for other modules
- `README.md` - Module documentation with examples

**Module Dependencies:**
- Clear dependency chain between modules
- Base module provides foundation for all others
- Conditional resource creation based on feature flags

### Security Implementation
- **Network Policies**: Restrict pod-to-pod communication
- **RBAC**: Minimal privilege service accounts and roles
- **TLS Encryption**: End-to-end encryption with automatic certificate management
- **Service Mesh Security**: mTLS between services via Istio
- **Secret Management**: Kubernetes secrets with proper access controls

### Monitoring and Observability
- **Metrics Collection**: Prometheus with ServiceMonitors
- **Visualization**: Grafana with pre-configured dashboards
- **Alerting**: AlertManager with notification channels
- **Distributed Tracing**: Jaeger integration via Istio
- **Application Monitoring**: Health checks and custom metrics

## 🚀 Implementation Strategy

### Phase 1: Foundation
1. Create shared configuration and variable definitions
2. Implement `kubernetes-base` module with namespaces, RBAC, network policies
3. Set up basic staging environment configuration

### Phase 2: Core Services
1. Implement `data-services` module with PostgreSQL, Redis, ClickHouse, MinIO
2. Create `nginx-app` module as sample application
3. Add `cert-manager` module for TLS automation

### Phase 3: Advanced Features
1. Implement `networking` module with Istio service mesh
2. Create `observability` module with Prometheus stack
3. Add `security` module with Topaz.sh authorization
4. Implement `gitops` module with ArgoCD

### Phase 4: Production Readiness
1. Create production environment with HA configurations
2. Add comprehensive documentation and examples
3. Create troubleshooting guides and best practices

## 📚 Documentation Requirements

### Learning-Focused Documentation
The project must include extensive documentation designed for **unpracticed Terraform contributors** to understand:

- **Architecture Patterns**: Why modules are structured this way
- **Terraform Best Practices**: Variable validation, resource dependencies, state management
- **Kubernetes Patterns**: Resource quotas, network policies, service discovery
- **Cloud Native Concepts**: Service mesh, observability, GitOps workflows
- **Security Principles**: Zero-trust networking, least privilege access

### Required Documentation Files
- `README.md` - Project overview, quick start, architecture
- `docs/deployment-guide.md` - Step-by-step deployment instructions
- `docs/troubleshooting.md` - Common issues and solutions
- `docs/module-reference.md` - Detailed module documentation
- `examples/minimal-deployment/` - Simple example for learning

### Documentation Standards
- Clear explanations of **why** not just **how**
- Step-by-step instructions with expected outputs
- Troubleshooting sections for common issues
- Code examples with explanatory comments
- Architecture diagrams showing component relationships

## 🎓 Success Criteria

### Functional Requirements
- ✅ Deploys successfully on local Kubernetes (microk8s/Docker Desktop)
- ✅ All specified components are functional and properly configured
- ✅ Two environments with different resource profiles
- ✅ Comprehensive monitoring and logging
- ✅ End-to-end TLS encryption
- ✅ GitOps workflow with ArgoCD

### Quality Requirements
- ✅ Modular, reusable Terraform code
- ✅ Proper resource dependencies and error handling
- ✅ Security best practices implemented
- ✅ Comprehensive documentation for learning
- ✅ Production-ready configurations
- ✅ Multi-cloud compatibility

### Learning Objectives Met
- ✅ Demonstrates Terraform module design patterns
- ✅ Shows Kubernetes resource management best practices
- ✅ Illustrates cloud-native application architecture
- ✅ Provides hands-on experience with modern DevOps tools
- ✅ Teaches security and observability patterns

## 🤖 Agent Instructions

When implementing this project:

1. **Start with Foundation**: Begin with shared configuration and base module
2. **Build Incrementally**: Add one module at a time, testing dependencies
3. **Document Continuously**: Add README and documentation as you build
4. **Use Standards**: Leverage official providers and well-maintained Helm charts
5. **Think Production**: Consider scalability, security, and maintainability
6. **Enable Learning**: Include extensive comments and explanations

### Bootstrap Task
**IMPORTANT**: After completing the project implementation, create a `HCP_AGENT.md` file in the project root that documents:
- How this project demonstrates HCP Terraform capabilities
- Integration patterns with HCP Terraform workspaces
- Remote state management best practices
- Team collaboration workflows
- CI/CD integration examples

This file should serve as a bridge between the educational content and production HCP Terraform usage.

## 💡 Success Indicators

The project is complete when:
- A new Terraform practitioner can clone and deploy successfully
- All components are documented with clear explanations
- Both staging and production environments work as intended
- Security and monitoring are properly implemented
- The project serves as a reference for production deployments
- HCP Terraform integration guidance is provided

---

**Remember**: This is both a learning tool and a production foundation. Balance simplicity for learning with completeness for real-world usage.
