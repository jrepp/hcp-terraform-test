# HCP Terraform Integration Guide

This document demonstrates how the Terraform Kubernetes Demo Project integrates with HashiCorp Cloud Platform (HCP) Terraform for enterprise-grade infrastructure management.

## 🏢 HCP Terraform Overview

HCP Terraform (formerly Terraform Cloud) provides:
- **Remote State Management**: Centralized, secure state storage
- **Team Collaboration**: Shared workspaces and access controls
- **CI/CD Integration**: Automated runs and deployments
- **Policy as Code**: Sentinel policies for governance
- **Cost Estimation**: Infrastructure cost analysis
- **Private Registry**: Custom module sharing

## 🚀 Project Integration with HCP Terraform

### Workspace Configuration

This project is designed for HCP Terraform workspace deployment patterns:

#### 1. Environment-Based Workspaces

```hcl
# environments/staging/main.tf
terraform {
  backend "remote" {
    organization = "your-organization"
    workspaces {
      name = "k8s-demo-staging"
    }
  }
}

# environments/production/main.tf
terraform {
  backend "remote" {
    organization = "your-organization"
    workspaces {
      name = "k8s-demo-production"
    }
  }
}
```

#### 2. Feature-Based Workspaces

```hcl
# Alternative: Workspace per major component
terraform {
  backend "remote" {
    organization = "your-organization"
    workspaces {
      prefix = "k8s-demo-"
    }
  }
}
```

### Variable Management

HCP Terraform variable organization:

```hcl
# Workspace Variables (Environment-specific)
TF_VAR_environment = "staging"
TF_VAR_cluster_type = "gke"
TF_VAR_domain_name = "staging.yourcompany.com"

# Sensitive Variables (Encrypted)
TF_VAR_postgresql_password = "***"
TF_VAR_grafana_admin_password = "***"
TF_VAR_letsencrypt_email = "admin@yourcompany.com"

# Environment Variables
KUBE_CONFIG_FILE = "base64-encoded-kubeconfig"
TF_VAR_kubeconfig_path = "$KUBE_CONFIG_FILE"
```

## 🔧 Workspace Setup Guide

### Step 1: Create Organization Workspaces

```bash
# Using Terraform CLI
terraform login

# Create staging workspace
cat > staging-workspace.tf << EOF
terraform {
  backend "remote" {
    organization = "your-org"
    workspaces {
      name = "k8s-demo-staging"
    }
  }
}
EOF

# Create production workspace
cat > production-workspace.tf << EOF
terraform {
  backend "remote" {
    organization = "your-org"
    workspaces {
      name = "k8s-demo-production"
    }
  }
}
EOF
```

### Step 2: Configure Workspace Settings

**Staging Workspace:**
- **Execution Mode**: Remote
- **Terraform Version**: >= 1.5
- **Auto Apply**: Enabled (for development)
- **Speculative Plans**: Enabled

**Production Workspace:**
- **Execution Mode**: Remote
- **Terraform Version**: >= 1.5
- **Auto Apply**: Disabled (manual approval required)
- **Speculative Plans**: Enabled

### Step 3: Set Workspace Variables

**Common Variables for Both Workspaces:**
```hcl
# Infrastructure
project_name = "terraform-k8s-demo"
enable_monitoring = true
enable_istio = true
enable_cert_manager = true

# Security
enable_network_policies = true
enable_tls = true
```

**Staging-Specific Variables:**
```hcl
environment = "staging"
cluster_type = "gke"
domain_name = "staging.example.com"
enable_letsencrypt = false  # Use self-signed for staging
```

**Production-Specific Variables:**
```hcl
environment = "production"
cluster_type = "gke"
domain_name = "prod.example.com"
enable_letsencrypt = true   # Use Let's Encrypt for production
```

## 🔐 Security and Access Control

### Team Access Patterns

```hcl
# Platform Team (Full Access)
teams = {
  platform = {
    organization_access = "manage-workspaces"
    workspace_access = {
      "k8s-demo-*" = "admin"
    }
  }
  
  # Development Team (Staging Only)
  developers = {
    workspace_access = {
      "k8s-demo-staging" = "plan"
    }
  }
  
  # Operations Team (Production)
  operations = {
    workspace_access = {
      "k8s-demo-production" = "write"
    }
  }
}
```

### Kubernetes Authentication

```bash
# Store kubeconfig as environment variable
export KUBE_CONFIG=$(cat ~/.kube/config | base64 -w 0)

# Set in HCP Terraform workspace
TF_VAR_kubeconfig_content = "$KUBE_CONFIG"
```

## 📊 CI/CD Integration Patterns

### GitHub Actions Integration

```yaml
# .github/workflows/terraform.yml
name: 'Terraform'

on:
  push:
    branches: [main]
    paths: ['environments/**']
  pull_request:
    branches: [main]
    paths: ['environments/**']

jobs:
  terraform:
    name: 'Terraform'
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        environment: [staging, production]
    
    steps:
    - name: Checkout
      uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}
    
    - name: Terraform Init
      run: terraform init
      working-directory: ./environments/${{ matrix.environment }}
    
    - name: Terraform Plan
      run: terraform plan
      working-directory: ./environments/${{ matrix.environment }}
    
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && matrix.environment == 'staging'
      run: terraform apply -auto-approve
      working-directory: ./environments/${{ matrix.environment }}
```

### GitLab CI Integration

```yaml
# .gitlab-ci.yml
stages:
  - validate
  - plan
  - apply

variables:
  TF_ROOT: ${CI_PROJECT_DIR}
  TF_ADDRESS: ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/default
  TF_USERNAME: gitlab-ci-token
  TF_PASSWORD: ${CI_JOB_TOKEN}

.terraform_template: &terraform_template
  image: hashicorp/terraform:latest
  before_script:
    - cd environments/${ENVIRONMENT}
    - terraform init

staging_plan:
  <<: *terraform_template
  stage: plan
  variables:
    ENVIRONMENT: staging
  script:
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - environments/staging/tfplan

production_plan:
  <<: *terraform_template
  stage: plan
  variables:
    ENVIRONMENT: production
  script:
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - environments/production/tfplan
```

## 📋 Policy as Code with Sentinel

### Cost Control Policy

```hcl
# policies/cost-control.sentinel
import "tfplan-functions" as plan
import "tfconfig-functions" as config

# Limit monthly cost for staging environment
monthly_cost_limit = rule {
  plan.filter_attribute_values(plan.planned_values.root_module, "tags.Environment", "staging") or
  tfplan.monthly_cost < 100
}

# Require specific instance types for production
production_instance_types = ["e2-standard-4", "e2-standard-8"]

instance_type_check = rule {
  all plan.filter_attribute_values(plan.planned_values.root_module, "tags.Environment", "production") as instances {
    instances.machine_type in production_instance_types
  }
}

main = rule {
  monthly_cost_limit and instance_type_check
}
```

### Security Policy

```hcl
# policies/security-requirements.sentinel
import "tfconfig-functions" as config

# Require network policies to be enabled
network_policies_required = rule {
  config.find_resources_by_type("kubernetes_network_policy") is not empty
}

# Require TLS to be enabled in production
tls_required = rule when config.find_variables_by_name("environment").default is "production" {
  config.find_variables_by_name("enable_tls").default is true
}

main = rule {
  network_policies_required and tls_required
}
```

## 🏗️ Module Registry Integration

### Publishing Modules

```hcl
# Create module registry entries
module "kubernetes_base" {
  source  = "app.terraform.io/your-org/kubernetes-base/kubernetes"
  version = "~> 1.0"
  
  environment = var.environment
  namespace   = var.kubernetes_namespace
}

module "data_services" {
  source  = "app.terraform.io/your-org/data-services/kubernetes"
  version = "~> 1.0"
  
  environment = var.environment
  namespace   = module.kubernetes_base.namespace_name
}
```

### Versioning Strategy

```
v1.0.0 - Initial release with basic functionality
v1.1.0 - Added monitoring and observability features
v1.2.0 - Enhanced security with Istio integration
v2.0.0 - Breaking changes for production readiness
```

## 🔄 State Management Best Practices

### State Locking

```hcl
# Automatic with HCP Terraform remote backend
terraform {
  backend "remote" {
    organization = "your-organization"
    workspaces {
      name = "k8s-demo-staging"
    }
  }
}
```

### State Sharing Between Workspaces

```hcl
# Reference outputs from other workspaces
data "terraform_remote_state" "base_infrastructure" {
  backend = "remote"
  
  config = {
    organization = "your-organization"
    workspaces = {
      name = "k8s-base-infrastructure"
    }
  }
}

locals {
  cluster_name = data.terraform_remote_state.base_infrastructure.outputs.cluster_name
  vpc_id       = data.terraform_remote_state.base_infrastructure.outputs.vpc_id
}
```

## 📈 Monitoring and Notifications

### Run Notifications

```hcl
# Webhook notifications for run status
webhook_notifications = {
  destination_type = "slack"
  enabled         = true
  name           = "k8s-demo-notifications"
  triggers       = ["run:applying", "run:completed", "run:errored"]
  url            = "https://hooks.slack.com/services/..."
}
```

### Cost Monitoring

```hcl
# Cost estimation alerts
cost_estimation = {
  enabled = true
  
  # Alert when monthly cost exceeds threshold
  monthly_cost_threshold = {
    staging    = 100
    production = 1000
  }
}
```

## 🎯 Migration from Local State

### Step 1: Backup Local State

```bash
# Backup existing local state
cp terraform.tfstate terraform.tfstate.backup
cp terraform.tfstate.backup ~/backups/k8s-demo-$(date +%Y%m%d).tfstate
```

### Step 2: Configure Remote Backend

```hcl
# Add to main.tf
terraform {
  backend "remote" {
    organization = "your-organization"
    workspaces {
      name = "k8s-demo-staging"
    }
  }
}
```

### Step 3: Migrate State

```bash
# Initialize with new backend
terraform init

# Migrate state (when prompted)
# Answer 'yes' to copy existing state to new backend

# Verify migration
terraform plan  # Should show no changes
```

## 🔍 Troubleshooting HCP Integration

### Common Issues

1. **Authentication Errors**
   ```bash
   # Login to HCP Terraform
   terraform login
   
   # Verify token
   cat ~/.terraform.d/credentials.tfrc.json
   ```

2. **Workspace Not Found**
   ```bash
   # Check workspace exists
   terraform workspace list
   
   # Create if missing
   terraform workspace new staging
   ```

3. **Variable Conflicts**
   ```bash
   # Check workspace variables in HCP Terraform UI
   # Ensure no conflicts between .tfvars and workspace variables
   ```

### Debug Commands

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run terraform with verbose output
terraform plan -refresh=true -detailed-exitcode

# Check remote state
terraform refresh
terraform show
```

## 📚 Additional Resources

- [HCP Terraform Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/remote)
- [Sentinel Policy Language](https://docs.hashicorp.com/sentinel/)
- [Terraform Module Registry](https://registry.terraform.io/)

## 🎉 Success Metrics

Your HCP Terraform integration is successful when:

✅ **Workspaces are properly configured** with appropriate access controls  
✅ **Remote state is secure** and accessible to team members  
✅ **CI/CD pipelines** automatically trigger terraform runs  
✅ **Policy as Code** enforces governance requirements  
✅ **Cost monitoring** provides visibility into infrastructure spend  
✅ **Module sharing** enables reuse across teams  
✅ **Collaboration workflows** support team development  

---

**This project demonstrates production-ready patterns for managing Kubernetes infrastructure at scale with HCP Terraform.**
