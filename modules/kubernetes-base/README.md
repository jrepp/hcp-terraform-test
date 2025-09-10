# modules/kubernetes-base/README.md
# Kubernetes Base Module

This module creates the fundamental Kubernetes resources needed for any environment deployment.

## Purpose

The `kubernetes-base` module establishes the foundation for all other modules by creating:

- **Namespace**: Isolated environment for resources
- **Service Account**: Identity for applications with minimal required permissions
- **RBAC**: Cluster role and binding for secure access
- **Network Policies**: Traffic isolation and security boundaries
- **Resource Management**: Quotas and limits to prevent resource exhaustion
- **Configuration**: Base configuration accessible to all applications

## Features

### 🔒 Security First
- Service accounts with principle of least privilege
- Network policies for traffic isolation (optional)
- RBAC with minimal required permissions

### 📊 Resource Management
- Resource quotas to prevent cluster resource exhaustion
- Limit ranges for default container resource constraints
- Configurable limits per environment

### 🏷️ Consistent Labeling
- Standard labels applied to all resources
- Environment-specific tagging
- Kubernetes recommended labels

## Usage

```hcl
module "kubernetes_base" {
  source = "../../modules/kubernetes-base"
  
  environment   = "staging"
  project_name  = "my-app"
  namespace     = "my-app-staging"
  domain_name   = "staging.myapp.com"
  cluster_type  = "microk8s"
  
  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "my-app"
  }
  
  enable_network_policies = true
  
  resource_limits = {
    cpu_requests    = "1"
    memory_requests = "2Gi"
    cpu_limits      = "2"
    memory_limits   = "4Gi"
    pvc_count      = 5
    service_count  = 10
    pod_count      = 20
  }
}
```

## Resource Quotas

The module creates resource quotas to prevent any single namespace from consuming excessive cluster resources:

| Resource Type | Purpose | Configurable |
|---------------|---------|--------------|
| CPU Requests | Minimum guaranteed CPU | ✅ |
| CPU Limits | Maximum CPU usage | ✅ |
| Memory Requests | Minimum guaranteed memory | ✅ |
| Memory Limits | Maximum memory usage | ✅ |
| PVCs | Number of persistent volume claims | ✅ |
| Services | Number of services | ✅ |
| Pods | Number of pods | ✅ |

## Network Policies

When `enable_network_policies = true`, the module creates:

1. **Default Deny All**: Blocks all traffic by default
2. **Allow Same Namespace**: Permits communication within the namespace
3. **Allow DNS**: Enables DNS resolution for all pods

This implements a "default deny" security posture where communication must be explicitly allowed.

## Service Account Permissions

The created service account has minimal permissions:

- **Read-only** access to pods, services, and endpoints
- **Read-only** access to deployments and replica sets
- **No** cluster-admin or elevated privileges

Additional permissions should be granted by other modules as needed.

## Configuration Map

The module creates a configuration map with common application settings:

```yaml
environment: staging
namespace: my-app-staging
project_name: my-app
domain_name: staging.myapp.com
cluster_type: microk8s
log_level: info
enable_debug: "false"
```

This configuration is available to all applications in the namespace.

## Best Practices

### Resource Sizing
- Start with conservative limits and increase as needed
- Monitor actual usage vs. requested resources
- Set appropriate default limits for containers

### Security
- Keep network policies enabled in production
- Regularly review service account permissions
- Use separate namespaces for different environments

### Labeling
- Use consistent labels across all resources
- Include environment and component information
- Follow Kubernetes labeling best practices

## Troubleshooting

### Common Issues

1. **Resource Quota Exceeded**
   ```
   Error: pods "my-pod" is forbidden: exceeded quota
   ```
   Solution: Increase resource quotas or reduce resource requests

2. **Network Policy Blocking Traffic**
   ```
   Error: connection timeout
   ```
   Solution: Create additional network policies to allow required traffic

3. **Permission Denied**
   ```
   Error: serviceaccount cannot get pods
   ```
   Solution: Update cluster role with required permissions

### Debugging Commands

```bash
# Check resource quota usage
kubectl describe quota -n <namespace>

# View limit ranges
kubectl describe limitrange -n <namespace>

# Check network policies
kubectl get networkpolicy -n <namespace>

# View service account
kubectl describe sa <service-account> -n <namespace>
```

## Dependencies

This module has no dependencies on other modules and should be applied first in any environment.

## Related Modules

This base module is used by:
- `data-services` - Database and storage services
- `observability` - Monitoring and logging
- `security` - Security and authorization components
- `networking` - Service mesh and ingress
- `gitops` - ArgoCD and GitOps tools
