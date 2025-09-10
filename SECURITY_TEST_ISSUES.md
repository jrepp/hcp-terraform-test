# Security Test Issues - Branch: security-test-vulnerabilities

This branch contains **intentional security vulnerabilities** for testing and educational purposes. These issues simulate common misconfigurations that occur in real Terraform Kubernetes deployments.

## ⚠️ **WARNING: DO NOT USE IN PRODUCTION**

This branch contains deliberate security vulnerabilities and should **NEVER** be deployed to production environments.

## 🔍 Security Issues Introduced

### Issue 1: Overly Permissive RBAC
**Location**: `modules/kubernetes-base/main.tf`
**Type**: Authorization/Access Control

**Problem**: The Kubernetes Role has been modified with excessive permissions:
- Grants full access (`create`, `update`, `delete`) to all secrets
- Allows access to all resources with wildcard permissions
- Violates principle of least privilege

**Impact**: 
- Applications can access sensitive secrets they shouldn't
- Potential for lateral movement within the namespace
- Risk of accidental or malicious data modification

**Detection Methods**:
- RBAC analysis tools (kubectl-who-can, rbac-tool)
- Static code analysis (Checkov, tfsec)
- Policy as Code (OPA Gatekeeper, Sentinel)

### Issue 2: Disabled Network Policies
**Location**: `modules/data-services/main.tf`
**Type**: Network Security

**Problem**: Network policies for ClickHouse are disabled:
- Logic error: `false ?` always evaluates to false
- Creates unrestricted network access to database
- Allows any pod to connect to ClickHouse

**Impact**:
- Unrestricted database access from any pod
- Potential for data exfiltration
- No network-level isolation between services

**Detection Methods**:
- Network policy auditing tools
- Pod connectivity testing
- Security scanning (Falco, Twistlock)

### Issue 3: Privileged Container Configuration
**Location**: `modules/nginx-app/main.tf`
**Type**: Container Security

**Problem**: Container runs with dangerous privileges:
- Runs as root user (UID 0)
- Allows privilege escalation
- Privileged container mode enabled
- All Linux capabilities granted

**Impact**:
- Container escape possibilities
- Host system compromise risk
- Excessive privileges for simple web server

**Detection Methods**:
- Pod Security Standards/Pod Security Policies
- Container security scanners (Trivy, Clair)
- Runtime security monitoring (Falco)

## 🔧 Testing These Issues

### Automated Detection

```bash
# Test with tfsec (Terraform security scanner)
tfsec .

# Test with Checkov
checkov -d . --framework terraform

# Test with Terrascan
terrascan scan -t terraform

# Test with kube-score (if deployed)
kubectl get pods -o yaml | kube-score score -
```

### Manual Verification

```bash
# Check RBAC permissions
kubectl auth can-i create secrets --as=system:serviceaccount:staging:app-service-account

# Check network policies
kubectl get networkpolicy -n staging
kubectl describe networkpolicy -n staging

# Check pod security contexts
kubectl get pods -n staging -o jsonpath='{.items[*].spec.securityContext}' | jq

# Check container security contexts
kubectl get pods -n staging -o jsonpath='{.items[*].spec.containers[*].securityContext}' | jq
```

### Runtime Testing

```bash
# Test if nginx pod has excessive privileges
kubectl exec -it <nginx-pod> -n staging -- whoami
kubectl exec -it <nginx-pod> -n staging -- id

# Test if pod can access other secrets
kubectl exec -it <nginx-pod> -n staging -- sh -c "cat /var/run/secrets/kubernetes.io/serviceaccount/token"

# Test network connectivity (should be restricted but isn't)
kubectl exec -it <nginx-pod> -n staging -- nc -zv <clickhouse-service> 5432
```

## 🛡️ Remediation Guide

### Fix Issue 1: RBAC Permissions
```hcl
# Remove excessive permissions
rule {
  api_groups = [""]
  resources  = ["pods", "services", "configmaps"]
  verbs      = ["get", "list", "watch"]  # Read-only
}

rule {
  api_groups = [""]
  resources  = ["secrets"]
  verbs      = ["get"]
  resource_names = ["app-config"]  # Specific secrets only
}
```

### Fix Issue 2: Network Policies
```hcl
# Enable network policies properly
networkPolicy = var.enable_network_policies ? {
  enabled = true
} : {
  enabled = false
}
```

### Fix Issue 3: Container Security
```hcl
security_context {
  allow_privilege_escalation = false
  run_as_non_root           = true
  run_as_user               = 101
  privileged                = false
  read_only_root_filesystem = true
  capabilities {
    drop = ["ALL"]
  }
}
```

## 📊 Security Testing Checklist

- [ ] **RBAC Analysis**: Verify service accounts have minimal required permissions
- [ ] **Network Policies**: Ensure all pods have appropriate network restrictions
- [ ] **Pod Security**: Check security contexts prevent privilege escalation
- [ ] **Secret Management**: Verify secrets are properly scoped and accessed
- [ ] **Container Images**: Scan for vulnerabilities and use non-root images
- [ ] **Resource Limits**: Ensure proper resource quotas and limits
- [ ] **Admission Controllers**: Test with Pod Security Standards
- [ ] **Runtime Security**: Monitor for suspicious activity

## 🎯 Learning Objectives

This branch helps you learn:

1. **Common Security Misconfigurations** in Kubernetes
2. **Detection Methods** for identifying security issues
3. **Impact Assessment** of security vulnerabilities
4. **Remediation Techniques** for fixing issues
5. **Security Testing** methodologies and tools

## 🔄 Branch Management

```bash
# Switch back to secure main branch
git checkout main

# Compare differences
git diff main security-test-vulnerabilities

# Delete test branch (when done testing)
git branch -D security-test-vulnerabilities
```

---

**Remember**: These vulnerabilities are intentional for testing. Always follow security best practices in real deployments!
