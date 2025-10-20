# Automation Scripts

This directory contains automation scripts for installing, deploying, and managing the Astra Platform.

## 📋 Available Scripts

### Installation & Setup

#### `install.sh` / `install.ps1`
Install Crossplane and the Astra Platform on your Kubernetes cluster.

**Usage:**
```bash
./scripts/install.sh
```

**What it does:**
- Installs Crossplane using Helm
- Configures Azure provider for Crossplane
- Creates necessary Azure credentials secret
- Deploys platform XRDs and Compositions
- Validates installation

**Requirements:**
- Kubernetes cluster (Minikube recommended, Docker Desktop, or AKS)
- kubectl configured
- Helm installed
- Minikube (for local development)
- Azure credentials set as environment variables

---

### Deployment

#### `deploy.sh`
Deploy the platform to a specific environment (dev/staging/prod).

**Usage:**
```bash
# Deploy to development
./scripts/deploy.sh dev --wait

# Deploy to production with custom image
./scripts/deploy.sh prod --image "myregistry.azurecr.io/myapp:v2.0.0" --wait

# Deploy and show URLs
./scripts/deploy.sh staging --urls

# Dry-run (validate without applying)
./scripts/deploy.sh dev --dry-run
```

**Options:**
- `--wait`: Wait for resources to be ready
- `--image <image>`: Specify custom container image
- `--urls`: Display application URLs after deployment
- `--dry-run`: Validate without applying changes

---

### Azure Resource Creation

#### `create-azure-resources.sh`
Create Azure resources using Azure CLI commands instead of Crossplane.

**Usage:**
```bash
# Create resources for development environment
./scripts/create-azure-resources.sh dev

# Create resources with custom prefix
RESOURCE_PREFIX=myapp ./scripts/create-azure-resources.sh prod

# Create resources in different region
AZURE_LOCATION=eastus ./scripts/create-azure-resources.sh staging
```

**📚 Complete Documentation:**
For detailed documentation, configuration options, examples, and troubleshooting, see:
**[docs/operations/azure-resources-creation.md](../docs/operations/azure-resources-creation.md)**

The documentation includes:
- Quick start guide
- Complete configuration variable reference
- Resource naming conventions
- 10+ usage examples (custom prefixes, premium SKUs, multi-region, etc.)
- Step-by-step resource creation process
- Post-creation deployment steps
- Troubleshooting guide
- Advanced usage patterns

**Quick Reference:**
```bash
# Default usage
./scripts/create-azure-resources.sh dev

# Custom prefix
RESOURCE_PREFIX=myapp ./scripts/create-azure-resources.sh dev

# Premium SKUs
CONTAINER_REGISTRY_SKU=Premium \
CONTAINER_APP_ENVIRONMENT_TYPE=WorkloadProfiles \
./scripts/create-azure-resources.sh prod

# Different region
AZURE_LOCATION=westus2 ./scripts/create-azure-resources.sh staging
```

---

### Secret Management

#### `manage-secrets.sh`
Manage Azure credentials and secrets for the platform.

**Usage:**
```bash
# Create Azure Service Principal
./scripts/manage-secrets.sh create-sp

# Create Kubernetes secret with Azure credentials
./scripts/manage-secrets.sh create-secret

# Rotate credentials
./scripts/manage-secrets.sh rotate

# Validate credentials
./scripts/manage-secrets.sh validate
```

**What it does:**
- Creates Azure Service Principal with required permissions
- Stores credentials in Kubernetes secrets
- Rotates expired credentials
- Validates Azure connectivity

---

### Testing

#### `test.sh`
Run tests for a specific test suite.

**Usage:**
```bash
# Run unit tests
./scripts/test.sh unit

# Run integration tests
./scripts/test.sh integration

# Run E2E tests
./scripts/test.sh e2e
```

#### `test-all.sh`
Run all test suites (unit, integration, and E2E).

**Usage:**
```bash
./scripts/test-all.sh
```

**What it does:**
- Runs XRD validation tests
- Executes Azure resource integration tests
- Performs environment E2E tests
- Generates test reports

---

### Cleanup

#### `cleanup.sh`
Clean up platform resources and Azure resources.

**Usage:**
```bash
# Interactive cleanup (prompts for confirmation)
./scripts/cleanup.sh

# Force cleanup without prompts
./scripts/cleanup.sh --force

# Clean specific environment
./scripts/cleanup.sh --environment dev

# Clean Azure resources only
./scripts/cleanup.sh --azure-only

# Clean Kubernetes resources only
./scripts/cleanup.sh --k8s-only
```

**Options:**
- `--force`: Skip confirmation prompts
- `--environment <env>`: Clean specific environment (dev/staging/prod)
- `--azure-only`: Only clean Azure resources
- `--k8s-only`: Only clean Kubernetes resources

**⚠️ Warning:** This will delete resources. Use with caution, especially in production.

---

## 🔧 Common Workflows

### Initial Setup
```bash
# 1. Set Azure credentials
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_SUBSCRIPTION_ID="your-subscription-id"

# 2. Install platform
./scripts/install.sh

# 3. Create Azure resources (optional - alternative to Crossplane)
./scripts/create-azure-resources.sh dev

# 4. Deploy to development
./scripts/deploy.sh dev --wait

# 5. Get application URL
./scripts/deploy.sh dev --urls
```

### Development Cycle
```bash
# Make changes to platform definitions
vim packages/platform/composition.yaml

# Validate changes
./scripts/test.sh unit

# Deploy to dev
./scripts/deploy.sh dev --wait

# Test the deployment
./scripts/test.sh e2e
```

### Multi-Environment Deployment
```bash
# Deploy to all environments
./scripts/deploy.sh dev --wait
./scripts/deploy.sh staging --wait
./scripts/deploy.sh prod --wait

# Verify deployments
kubectl get xplatform -A
```

### Cleanup and Reinstall
```bash
# Clean up everything
./scripts/cleanup.sh --force

# Reinstall platform
./scripts/install.sh

# Redeploy
./scripts/deploy.sh dev --wait
```

---

## 🌍 Environment Support

All deployment scripts support three environments:

| Environment | Namespace | Purpose |
|------------|-----------|---------|
| `dev` | `astra-dev` | Development and testing |
| `staging` | `astra-staging` | Pre-production validation |
| `prod` | `astra-prod` | Production workloads |

---

## 🔐 Required Permissions

Scripts require the following Azure permissions:

- **Contributor** role on the Azure subscription (for resource creation)
- **User Access Administrator** (for role assignments)

For Kubernetes operations:
- **cluster-admin** role or equivalent permissions

---

## 📝 Script Requirements

### Prerequisites
- **Bash** (for `.sh` scripts) or **PowerShell** (for `.ps1` scripts)
- **kubectl** - Kubernetes command-line tool
- **helm** - Kubernetes package manager
- **Azure CLI** (`az`) - For Azure resource management
- **jq** - JSON processor (for some scripts)

### Platform Requirements
- **macOS**: All scripts supported
- **Linux**: All `.sh` scripts supported
- **Windows**: Use `.ps1` PowerShell scripts or WSL for `.sh` scripts

---

## 🐛 Troubleshooting

### Script Execution Issues

**Problem:** Permission denied
```bash
chmod +x scripts/*.sh
```

**Problem:** Azure authentication failed
```bash
# Verify credentials
az login
az account show

# Or set environment variables
export AZURE_CLIENT_ID="..."
export AZURE_CLIENT_SECRET="..."
export AZURE_TENANT_ID="..."
export AZURE_SUBSCRIPTION_ID="..."
```

**Problem:** Kubernetes connection failed
```bash
# Verify cluster connection
kubectl cluster-info
kubectl get nodes
```

### Common Script Errors

See the [Troubleshooting Guide](../docs/troubleshooting/debugging.md) for detailed debugging steps.

---

## 📚 Additional Documentation

- **[Azure Resources Creation Guide](../docs/operations/azure-resources-creation.md)** - Complete Azure CLI automation documentation
- **[CI/CD Setup](../docs/operations/cicd-setup.md)** - Azure DevOps pipeline setup
- **[Deployment Guide](../docs/user-guides/application-deployment.md)** - Application deployment guide
- **[Troubleshooting](../docs/troubleshooting/debugging.md)** - Debugging and troubleshooting

---

## 🤝 Contributing

When adding new scripts:

1. Follow the existing naming convention
2. Add appropriate error handling
3. Include usage documentation in comments
4. Add the script to this README
5. Test on multiple platforms (if applicable)
6. Update related documentation in the `docs/` folder

---

**Built with ❤️ by the Astra Platform Team**
