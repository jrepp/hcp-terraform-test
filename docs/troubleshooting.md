# Troubleshooting Guide

This guide helps you diagnose and resolve common issues when deploying and running the Terraform Kubernetes demo project.

## 🚨 Common Issues and Solutions

### 1. Terraform Issues

#### Issue: Provider Authentication Errors

**Symptoms:**
```
Error: Failed to configure the Kubernetes provider
Error: Invalid provider configuration
```

**Solutions:**

1. **Check kubeconfig:**
   ```bash
   # Verify kubectl access
   kubectl cluster-info
   kubectl get nodes
   
   # Check current context
   kubectl config current-context
   kubectl config get-contexts
   ```

2. **Set correct kubeconfig path:**
   ```hcl
   # In terraform.tfvars
   kubeconfig_path = "/home/user/.kube/config"
   kube_context    = "docker-desktop"  # or your cluster context
   ```

3. **For cloud providers:**
   ```bash
   # GKE
   gcloud container clusters get-credentials cluster-name --zone=zone-name
   
   # EKS
   aws eks update-kubeconfig --region region-code --name cluster-name
   
   # AKS
   az aks get-credentials --resource-group rg-name --name cluster-name
   ```

#### Issue: Terraform State Lock

**Symptoms:**
```
Error: Error locking state: Error acquiring the state lock
```

**Solutions:**

1. **Force unlock (use carefully):**
   ```bash
   terraform force-unlock LOCK_ID
   ```

2. **Check for stuck processes:**
   ```bash
   ps aux | grep terraform
   kill -9 <terraform-pid>
   ```

3. **Use remote backend:**
   ```hcl
   # In main.tf
   terraform {
     backend "remote" {
       organization = "your-org"
       workspaces {
         name = "staging"
       }
     }
   }
   ```

#### Issue: Module Source Errors

**Symptoms:**
```
Error: Module not found
Error: Could not download module
```

**Solutions:**

1. **Use relative paths:**
   ```hcl
   module "kubernetes_base" {
     source = "../../modules/kubernetes-base"
   }
   ```

2. **Check file permissions:**
   ```bash
   ls -la modules/
   chmod -R 755 modules/
   ```

### 2. Kubernetes Issues

#### Issue: Pods Stuck in Pending State

**Diagnosis:**
```bash
kubectl get pods -n staging
kubectl describe pod <pod-name> -n staging
```

**Common Causes and Solutions:**

1. **Insufficient Resources:**
   ```bash
   # Check node resources
   kubectl top nodes
   kubectl describe nodes
   
   # Solution: Reduce resource requests or add nodes
   ```

2. **Storage Issues:**
   ```bash
   # Check storage classes
   kubectl get storageclass
   
   # Check PVCs
   kubectl get pvc -n staging
   kubectl describe pvc <pvc-name> -n staging
   
   # Solution: Create or configure storage class
   ```

3. **Node Affinity Issues:**
   ```bash
   # Check node labels
   kubectl get nodes --show-labels
   
   # Solution: Update node selectors or add labels
   kubectl label nodes <node-name> node-role.kubernetes.io/worker=true
   ```

#### Issue: Pods in CrashLoopBackOff

**Diagnosis:**
```bash
kubectl logs <pod-name> -n staging
kubectl logs <pod-name> -n staging --previous
kubectl describe pod <pod-name> -n staging
```

**Common Solutions:**

1. **Database Connection Issues:**
   ```bash
   # Test DNS resolution
   kubectl run debug --image=busybox -n staging --rm -it -- nslookup postgresql-service
   
   # Test database connectivity
   kubectl run debug --image=postgres:13 -n staging --rm -it -- \
     psql -h postgresql-service -U appuser -d appdb
   ```

2. **Configuration Issues:**
   ```bash
   # Check configmaps
   kubectl get configmap -n staging
   kubectl describe configmap <configmap-name> -n staging
   
   # Check secrets
   kubectl get secrets -n staging
   kubectl describe secret <secret-name> -n staging
   ```

3. **Image Issues:**
   ```bash
   # Check image pull status
   kubectl describe pod <pod-name> -n staging | grep -A 10 Events
   
   # Solution: Verify image names and registry access
   ```

#### Issue: Services Not Accessible

**Diagnosis:**
```bash
kubectl get svc -n staging
kubectl describe svc <service-name> -n staging
kubectl get endpoints -n staging
```

**Solutions:**

1. **Check Service Selectors:**
   ```bash
   # Verify pod labels match service selectors
   kubectl get pods -n staging --show-labels
   kubectl describe svc <service-name> -n staging
   ```

2. **Network Policy Issues:**
   ```bash
   # Check network policies
   kubectl get networkpolicy -n staging
   kubectl describe networkpolicy <policy-name> -n staging
   
   # Temporarily disable for testing
   kubectl delete networkpolicy <policy-name> -n staging
   ```

3. **Port Forward for Testing:**
   ```bash
   kubectl port-forward -n staging svc/<service-name> 8080:80
   curl http://localhost:8080
   ```

### 3. Helm Issues

#### Issue: Helm Release Failures

**Diagnosis:**
```bash
helm list -n staging
helm status <release-name> -n staging
helm get all <release-name> -n staging
```

**Solutions:**

1. **Check Helm Repositories:**
   ```bash
   helm repo list
   helm repo update
   helm search repo <chart-name>
   ```

2. **Debug Helm Templates:**
   ```bash
   helm template <release-name> <chart> --debug
   helm install <release-name> <chart> --dry-run --debug
   ```

3. **Rollback Failed Release:**
   ```bash
   helm rollback <release-name> <revision> -n staging
   helm history <release-name> -n staging
   ```

#### Issue: Chart Dependencies

**Symptoms:**
```
Error: found in Chart.yaml, but missing in charts/ directory
```

**Solutions:**
```bash
helm dependency update
helm dependency build
```

### 4. Istio Service Mesh Issues

#### Issue: Istio Injection Not Working

**Diagnosis:**
```bash
kubectl get namespace staging --show-labels
kubectl get pods -n staging -o wide
```

**Solutions:**

1. **Enable Istio Injection:**
   ```bash
   kubectl label namespace staging istio-injection=enabled
   kubectl rollout restart deployment -n staging
   ```

2. **Check Istio Installation:**
   ```bash
   kubectl get pods -n istio-system
   istioctl proxy-status
   istioctl analyze
   ```

3. **Verify Sidecar Injection:**
   ```bash
   kubectl describe pod <pod-name> -n staging
   # Should see istio-proxy container
   ```

#### Issue: Service-to-Service Communication

**Diagnosis:**
```bash
istioctl proxy-config cluster <pod-name> -n staging
istioctl proxy-config endpoint <pod-name> -n staging
```

**Solutions:**

1. **Check DestinationRules:**
   ```bash
   kubectl get destinationrule -n staging
   kubectl describe destinationrule <rule-name> -n staging
   ```

2. **Verify mTLS Settings:**
   ```bash
   istioctl authn tls-check <pod-name>.<namespace>
   ```

### 5. Certificate Management Issues

#### Issue: Let's Encrypt Certificate Failures

**Diagnosis:**
```bash
kubectl get certificates -n staging
kubectl describe certificate <cert-name> -n staging
kubectl get certificaterequests -n staging
kubectl describe certificaterequest <request-name> -n staging
```

**Solutions:**

1. **Check Rate Limits:**
   ```bash
   kubectl logs -n cert-manager deployment/cert-manager
   # Look for rate limit errors
   ```

2. **Verify DNS Challenge:**
   ```bash
   # For DNS challenges
   kubectl get challenges -n staging
   kubectl describe challenge <challenge-name> -n staging
   ```

3. **Use Staging Let's Encrypt:**
   ```hcl
   # In terraform.tfvars for testing
   letsencrypt_config = {
     email  = "test@example.com"
     server = "https://acme-staging-v02.api.letsencrypt.org/directory"
   }
   ```

#### Issue: Self-Signed Certificate Problems

**Solutions:**

1. **Recreate Certificates:**
   ```bash
   kubectl delete certificate <cert-name> -n staging
   terraform apply  # Will recreate
   ```

2. **Check CA Certificate:**
   ```bash
   kubectl get secret ca-key-pair -n staging -o yaml
   ```

### 6. Monitoring Issues

#### Issue: Prometheus Not Scraping Metrics

**Diagnosis:**
```bash
kubectl port-forward -n staging svc/prometheus-server 9090:80
# Access http://localhost:9090/targets
```

**Solutions:**

1. **Check ServiceMonitor:**
   ```bash
   kubectl get servicemonitor -n staging
   kubectl describe servicemonitor <monitor-name> -n staging
   ```

2. **Verify Prometheus Configuration:**
   ```bash
   kubectl get secret prometheus-config -n staging -o yaml
   ```

3. **Check Network Policies:**
   ```bash
   kubectl get networkpolicy -n staging
   # Ensure monitoring traffic is allowed
   ```

#### Issue: Grafana Dashboard Loading Issues

**Solutions:**

1. **Check Grafana Logs:**
   ```bash
   kubectl logs -f deployment/grafana -n staging
   ```

2. **Verify Data Source:**
   ```bash
   # Port forward to Grafana
   kubectl port-forward -n staging svc/grafana 3000:80
   # Check data source connectivity
   ```

### 7. Database Issues

#### Issue: PostgreSQL Connection Refused

**Diagnosis:**
```bash
kubectl get pods -n staging -l app=postgresql
kubectl logs <postgresql-pod> -n staging
kubectl describe pod <postgresql-pod> -n staging
```

**Solutions:**

1. **Check Service DNS:**
   ```bash
   kubectl run debug --image=busybox -n staging --rm -it -- \
     nslookup postgresql-service
   ```

2. **Test Direct Connection:**
   ```bash
   kubectl exec -it <postgresql-pod> -n staging -- psql -U postgres
   ```

3. **Check Persistent Volume:**
   ```bash
   kubectl get pv,pvc -n staging
   kubectl describe pvc postgresql-pvc -n staging
   ```

#### Issue: Redis Authentication Failures

**Solutions:**

1. **Verify Password Secret:**
   ```bash
   kubectl get secret redis-password -n staging -o yaml
   echo "<password-base64>" | base64 -d
   ```

2. **Test Redis Connection:**
   ```bash
   kubectl exec -it <redis-pod> -n staging -- redis-cli ping
   kubectl exec -it <redis-pod> -n staging -- redis-cli auth <password>
   ```

### 8. Performance Issues

#### Issue: High Memory Usage

**Diagnosis:**
```bash
kubectl top pods -n staging
kubectl top nodes
kubectl describe node <node-name>
```

**Solutions:**

1. **Adjust Resource Limits:**
   ```hcl
   # In terraform.tfvars
   default_resources = {
     requests = {
       memory = "64Mi"
     }
     limits = {
       memory = "256Mi"
     }
   }
   ```

2. **Enable Horizontal Pod Autoscaling:**
   ```bash
   kubectl get hpa -n staging
   kubectl describe hpa <hpa-name> -n staging
   ```

#### Issue: Slow Application Response

**Solutions:**

1. **Check Resource Constraints:**
   ```bash
   kubectl describe pod <pod-name> -n staging
   # Look for CPU/Memory throttling
   ```

2. **Analyze Network Latency:**
   ```bash
   istioctl proxy-config cluster <pod-name> -n staging
   ```

### 9. Security Issues

#### Issue: RBAC Permission Denied

**Diagnosis:**
```bash
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:staging:<sa-name>
kubectl describe role,rolebinding -n staging
```

**Solutions:**

1. **Check Service Account:**
   ```bash
   kubectl get serviceaccount -n staging
   kubectl describe serviceaccount <sa-name> -n staging
   ```

2. **Verify RBAC Bindings:**
   ```bash
   kubectl get rolebinding,clusterrolebinding -n staging
   ```

#### Issue: Network Policy Blocking Traffic

**Solutions:**

1. **Temporarily Remove Policies:**
   ```bash
   kubectl delete networkpolicy --all -n staging
   ```

2. **Adjust Policy Rules:**
   ```bash
   kubectl edit networkpolicy <policy-name> -n staging
   ```

## 🔍 Debugging Tools and Commands

### Essential Debugging Commands

```bash
# General cluster health
kubectl cluster-info
kubectl get nodes
kubectl get all -n staging

# Resource usage
kubectl top nodes
kubectl top pods -n staging

# Events and logs
kubectl get events -n staging --sort-by='.lastTimestamp'
kubectl logs -f <pod-name> -n staging
kubectl logs -f <pod-name> -c <container-name> -n staging

# Detailed resource information
kubectl describe pod <pod-name> -n staging
kubectl describe svc <service-name> -n staging
kubectl describe pvc <pvc-name> -n staging

# Network debugging
kubectl exec -it <pod-name> -n staging -- ping <target>
kubectl exec -it <pod-name> -n staging -- nslookup <service-name>
kubectl exec -it <pod-name> -n staging -- wget -O- <url>
```

### Istio Debugging

```bash
# Proxy status
istioctl proxy-status

# Configuration analysis
istioctl analyze

# Proxy configuration
istioctl proxy-config cluster <pod-name> -n staging
istioctl proxy-config listener <pod-name> -n staging
istioctl proxy-config route <pod-name> -n staging

# Traffic debugging
istioctl proxy-config log <pod-name> --level debug
```

### Debug Pod for Network Testing

```yaml
# debug-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
  namespace: staging
spec:
  containers:
  - name: debug
    image: nicolaka/netshoot
    command: ["sleep", "3600"]
```

```bash
kubectl apply -f debug-pod.yaml
kubectl exec -it debug-pod -n staging -- bash
```

## 📞 Getting Help

### Information to Include When Seeking Help

1. **Environment Details:**
   - Kubernetes version: `kubectl version`
   - Cluster type (microk8s, GKE, EKS, etc.)
   - Terraform version: `terraform version`

2. **Error Details:**
   - Full error messages
   - Relevant logs
   - Steps to reproduce

3. **Configuration:**
   - Terraform configuration (without secrets)
   - kubectl describe output for affected resources

4. **Troubleshooting Attempted:**
   - Commands run
   - Solutions tried
   - Results observed

### Useful Resources

- [Kubernetes Troubleshooting Guide](https://kubernetes.io/docs/tasks/debug-application-cluster/)
- [Terraform Debugging](https://www.terraform.io/docs/internals/debugging.html)
- [Istio Troubleshooting](https://istio.io/latest/docs/ops/troubleshooting/)
- [Helm Troubleshooting](https://helm.sh/docs/faq/)

---

**Remember**: Most issues are configuration-related. Carefully review your terraform.tfvars and verify cluster connectivity before seeking help.
