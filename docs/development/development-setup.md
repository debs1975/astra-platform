# Development Setup Guide

This guide walks you through setting up a complete development environment for the Astra Platform.

## 📋 Prerequisites

Before starting, ensure you have completed the [Prerequisites Guide](../getting-started/prerequisites.md).

## 🛠️ Development Environment Setup

### 1. Repository Setup

#### Clone the Repository
```bash
# Clone the repository
git clone <repository-url>
cd astra-platform

# Install git hooks (optional but recommended)
cp scripts/git-hooks/* .git/hooks/
chmod +x .git/hooks/*
```

#### Development Branch Strategy
```bash
# Create development branch from main
git checkout -b develop
git push -u origin develop

# Create feature branch from develop
git checkout -b feature/your-feature-name
```

### 2. Local Kubernetes Setup

#### Option A: Minikube (Recommended for Crossplane Development)
```bash
# Start Minikube with recommended resources for Crossplane
minikube start \
  --driver=docker \
  --cpus=4 \
  --memory=8192 \
  --disk-size=20g \
  --kubernetes-version=v1.28.0

# Verify cluster
kubectl cluster-info
kubectl get nodes

# Enable useful addons
minikube addons enable metrics-server
minikube addons enable dashboard

# View dashboard (optional)
minikube dashboard
```

**Minikube Tips for Crossplane:**
```bash
# Check Minikube status
minikube status

# SSH into Minikube node
minikube ssh

# View logs
minikube logs

# Increase resources if needed
minikube stop
minikube delete
minikube start --cpus=6 --memory=12288 --disk-size=30g
```

#### Option B: Docker Desktop
```bash
# Enable Kubernetes in Docker Desktop
# Go to Docker Desktop > Settings > Kubernetes > Enable Kubernetes

# Verify
kubectl cluster-info
kubectl get nodes
```

#### Option C: minikube
```bash
# Start minikube with sufficient resources
minikube start --memory=8192 --cpus=4 --disk-size=50g

# Enable addons
minikube addons enable ingress
minikube addons enable dashboard
```

### 3. Crossplane Development Setup

#### Install Crossplane for Development
```bash
# Install Crossplane
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm install crossplane \
  crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace \
  --version 1.14.0 \
  --set metrics.enabled=true

# Wait for Crossplane to be ready
kubectl wait --for=condition=ready pod -l app=crossplane --namespace crossplane-system --timeout=120s
```

#### Install Azure Provider for Development
```bash
# Install Azure provider with development settings
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure
spec:
  package: xpkg.upbound.io/upbound/provider-azure:v0.36.0
  packagePullPolicy: Always
  revisionActivationPolicy: Automatic
  revisionHistoryLimit: 1
EOF

# Monitor provider installation
kubectl get providers
kubectl wait --for=condition=healthy provider.pkg.crossplane.io/provider-azure --timeout=300s
```

### 4. Azure Credentials for Development

#### Create Development Service Principal
```bash
# Create service principal for development
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SP_NAME="astra-dev-sp"

az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --output json > sp-credentials.json

# Extract credentials
CLIENT_ID=$(jq -r '.appId' sp-credentials.json)
CLIENT_SECRET=$(jq -r '.password' sp-credentials.json)
TENANT_ID=$(jq -r '.tenant' sp-credentials.json)

# Clean up credentials file
rm sp-credentials.json
```

#### Create Development ProviderConfig
```bash
# Create Azure credentials secret
kubectl create secret generic azure-secret \
  -n crossplane-system \
  --from-literal=creds=$(echo '[
  {
    "clientId": "'$CLIENT_ID'",
    "clientSecret": "'$CLIENT_SECRET'",
    "subscriptionId": "'$SUBSCRIPTION_ID'",
    "tenantId": "'$TENANT_ID'",
    "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
    "resourceManagerEndpointUrl": "https://management.azure.com/",
    "activeDirectoryGraphResourceId": "https://graph.windows.net/",
    "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
    "galleryEndpointUrl": "https://gallery.azure.com/",
    "managementEndpointUrl": "https://management.core.windows.net/"
  }
]')

# Create ProviderConfig for development
cat <<EOF | kubectl apply -f -
apiVersion: azure.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: azure-secret
      key: creds
EOF
```

## 🔧 Development Tools Setup

### 1. Code Quality Tools

#### Install Development Dependencies
```bash
# YAML linting
pip install yamllint

# Kubernetes validation
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/$(uname -s | tr '[:upper:]' '[:lower:]')/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Helm chart linting
helm plugin install https://github.com/quintush/helm-unittest

# Shell script linting
brew install shellcheck  # macOS
# or
sudo apt-get install shellcheck  # Ubuntu
```

#### Configure Editor

**VS Code Extensions:**
```json
{
  "recommendations": [
    "ms-kubernetes-tools.vscode-kubernetes-tools",
    "redhat.vscode-yaml",
    "ms-azuretools.vscode-azurecli",
    "ms-vscode.vscode-json",
    "timonwong.shellcheck",
    "ms-vscode.makefile-tools"
  ]
}
```

**VS Code Settings:**
```json
{
  "yaml.schemas": {
    "https://raw.githubusercontent.com/crossplane/crossplane/master/cluster/crds/*.yaml": "packages/*/definition.yaml",
    "https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/swagger.json": "*.yaml"
  },
  "yaml.validate": true,
  "yaml.format.enable": true
}
```

### 2. Development Scripts

#### Create Development Helper Scripts
```bash
# Create dev script directory
mkdir -p scripts/dev

# Development validation script
cat <<'EOF' > scripts/dev/validate.sh
#!/bin/bash
set -euo pipefail

echo "🔍 Running development validation..."

# Validate YAML syntax
echo "Validating YAML syntax..."
find . -name "*.yaml" -o -name "*.yml" | while read -r file; do
    yamllint "$file" || echo "Warning: YAML lint issues in $file"
done

# Validate Kubernetes resources
echo "Validating Kubernetes resources..."
find packages -name "*.yaml" | while read -r file; do
    kubectl apply --dry-run=client -f "$file" &>/dev/null || echo "Warning: Invalid K8s resource in $file"
done

# Validate shell scripts
echo "Validating shell scripts..."
find scripts -name "*.sh" | while read -r file; do
    shellcheck "$file" || echo "Warning: ShellCheck issues in $file"
done

echo "✅ Validation complete!"
EOF
chmod +x scripts/dev/validate.sh

# Development testing script
cat <<'EOF' > scripts/dev/test.sh
#!/bin/bash
set -euo pipefail

echo "🧪 Running development tests..."

# Test XRD creation
echo "Testing XRD definitions..."
kubectl apply --dry-run=server -f packages/*/definition.yaml

# Test Composition creation
echo "Testing Compositions..."
kubectl apply --dry-run=server -f packages/*/composition.yaml

# Test platform claims
echo "Testing platform claims..."
kubectl apply --dry-run=server -f overlays/*/platform-claim.yaml

echo "✅ All tests passed!"
EOF
chmod +x scripts/dev/test.sh

# Development cleanup script
cat <<'EOF' > scripts/dev/clean.sh
#!/bin/bash
set -euo pipefail

echo "🧹 Cleaning development environment..."

# Clean up test resources
kubectl delete platforms.astra.platform --all --wait=false 2>/dev/null || true
kubectl delete xplatforms.astra.platform --all --wait=false 2>/dev/null || true

# Clean up dev namespace if exists
kubectl delete namespace astra-dev --wait=false 2>/dev/null || true

echo "✅ Development environment cleaned!"
EOF
chmod +x scripts/dev/clean.sh
```

### 3. Local Development Workflow

#### Start Development Session
```bash
# 1. Pull latest changes
git pull origin main

# 2. Create feature branch
git checkout -b feature/your-feature

# 3. Start development environment
kubectl cluster-info

# 4. Apply base XRDs for development
kubectl apply -f packages/*/definition.yaml

# 5. Apply compositions
kubectl apply -f packages/*/composition.yaml
```

#### Development Loop
```bash
# 1. Make changes to XRDs/Compositions
vim packages/containerapp/definition.yaml

# 2. Validate changes
scripts/dev/validate.sh

# 3. Test changes
scripts/dev/test.sh

# 4. Apply to development cluster
kubectl apply -f packages/containerapp/definition.yaml
kubectl apply -f packages/containerapp/composition.yaml

# 5. Test with claim
kubectl apply -f overlays/dev/platform-claim.yaml -n astra-dev

# 6. Monitor deployment
kubectl get xplatform -n astra-dev -w
```

## 🐛 Debugging Setup

### 1. Crossplane Debugging

#### Enable Debug Logging
```bash
# Update Crossplane deployment for debug logging
kubectl patch deployment crossplane \
  -n crossplane-system \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["--debug"]}]'
```

#### Debug Commands
```bash
# Check Crossplane status
kubectl get crossplane

# Check provider status
kubectl get providers
kubectl describe provider provider-azure

# Check XRD status
kubectl get xrd
kubectl describe xrd platforms.astra.platform

# Check composition status
kubectl get compositions
kubectl describe composition xplatform

# Check managed resources
kubectl get managed

# View Crossplane logs
kubectl logs -f deployment/crossplane -n crossplane-system

# View provider logs
kubectl logs -f deployment/crossplane-provider-azure -n crossplane-system
```

### 2. Azure Resource Debugging

#### Monitor Azure Resources
```bash
# List resource groups
az group list --query "[?starts_with(name, 'astra-')]"

# Monitor specific resource group
RESOURCE_GROUP="astra-dev-rg"
az resource list --resource-group "$RESOURCE_GROUP" --output table

# Check deployment status
az deployment group list --resource-group "$RESOURCE_GROUP" --output table

# View deployment details
DEPLOYMENT_NAME="latest-deployment"
az deployment group show --resource-group "$RESOURCE_GROUP" --name "$DEPLOYMENT_NAME"
```

### 3. Container App Debugging

#### Debug Container Apps
```bash
# List container apps
az containerapp list --output table

# Get container app details
CONTAINER_APP="astra-dev-app"
RESOURCE_GROUP="astra-dev-rg"
az containerapp show --name "$CONTAINER_APP" --resource-group "$RESOURCE_GROUP"

# View container app logs
az containerapp logs show --name "$CONTAINER_APP" --resource-group "$RESOURCE_GROUP"

# Check container app revisions
az containerapp revision list --name "$CONTAINER_APP" --resource-group "$RESOURCE_GROUP" --output table
```

## 🔄 Development Workflow Automation

### 1. Pre-commit Hooks

#### Setup Git Hooks
```bash
# Create pre-commit hook
cat <<'EOF' > .git/hooks/pre-commit
#!/bin/bash
set -e

echo "Running pre-commit validation..."

# Run validation
scripts/dev/validate.sh

# Run tests
scripts/dev/test.sh

echo "Pre-commit checks passed!"
EOF
chmod +x .git/hooks/pre-commit

# Create commit message hook
cat <<'EOF' > .git/hooks/commit-msg
#!/bin/bash
commit_regex='^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .{1,50}'

if ! grep -qE "$commit_regex" "$1"; then
    echo "Invalid commit message format!"
    echo "Format: type(scope): description"
    echo "Example: feat(containerapp): add auto-scaling support"
    exit 1
fi
EOF
chmod +x .git/hooks/commit-msg
```

### 2. Makefile for Development

```makefile
# Makefile
.PHONY: help validate test clean install deploy destroy dev-setup

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

validate: ## Validate all resources
	@scripts/dev/validate.sh

test: ## Run all tests
	@scripts/dev/test.sh

clean: ## Clean development environment
	@scripts/dev/clean.sh

install: ## Install Crossplane and providers
	@scripts/install.sh

deploy: ## Deploy to development environment
	@scripts/deploy.sh dev

destroy: ## Destroy development environment
	@scripts/cleanup.sh dev

dev-setup: install ## Complete development setup
	@echo "Development environment setup complete!"

dev-reset: clean install ## Reset development environment
	@echo "Development environment reset complete!"
```

### 3. Development Aliases

#### Bash/Zsh Aliases
```bash
# Add to ~/.bashrc or ~/.zshrc
alias k='kubectl'
alias kx='kubectl config current-context'
alias kns='kubectl config set-context --current --namespace'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'

# Crossplane specific
alias kgxr='kubectl get crossplane'
alias kgxrd='kubectl get xrd'
alias kgcomp='kubectl get compositions'
alias kgmanaged='kubectl get managed'

# Azure specific
alias azls='az account list --output table'
alias azset='az account set --subscription'
alias azrg='az group list --output table'

# Project specific
alias astra-validate='./scripts/dev/validate.sh'
alias astra-test='./scripts/dev/test.sh'
alias astra-clean='./scripts/dev/clean.sh'
alias astra-deploy='./scripts/deploy.sh dev'
```

## 📊 Development Monitoring

### 1. Resource Monitoring

#### Watch Resources
```bash
# Monitor all platforms
watch -n 5 'kubectl get xplatform -A'

# Monitor managed resources
watch -n 10 'kubectl get managed'

# Monitor Azure resources
watch -n 30 'az resource list --resource-group astra-dev-rg --output table'
```

#### Metrics and Logs
```bash
# Crossplane metrics (if enabled)
kubectl port-forward -n crossplane-system svc/crossplane 8080:8080
# Access metrics at http://localhost:8080/metrics

# Provider metrics
kubectl port-forward -n crossplane-system svc/crossplane-provider-azure 8081:8080
# Access metrics at http://localhost:8081/metrics
```

### 2. Development Dashboard

#### Create Development Namespace Dashboard
```yaml
# dev-dashboard.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dev-dashboard
  namespace: astra-dev
data:
  dashboard.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Astra Platform Development Dashboard</title>
        <meta http-equiv="refresh" content="30">
    </head>
    <body>
        <h1>Astra Platform Development Status</h1>
        <iframe src="/api/v1/namespaces/astra-dev/services/kubernetes-dashboard/proxy/" width="100%" height="800px"></iframe>
    </body>
    </html>
```

## 🚀 Next Steps

Now that your development environment is set up:

1. **Explore the Codebase**: Review the [Platform Architecture](../architecture/platform-architecture.md)
2. **Make Your First Change**: Follow the [Contributing Guide](contributing.md)
3. **Run Tests**: Execute the test suite to ensure everything works
4. **Deploy Dev Environment**: Use `./scripts/deploy.sh dev` to deploy your first platform

## 📚 Additional Resources

- [Crossplane Development Guide](https://crossplane.io/docs/latest/concepts/)
- [Azure Provider Documentation](https://marketplace.upbound.io/providers/upbound/provider-azure/)
- [Kubernetes Development Guide](https://kubernetes.io/docs/contribute/)
- [VS Code Kubernetes Extension](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools)

Happy coding! 🎉