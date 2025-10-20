#!/bin/bash

# Astra Platform Installation Script for macOS/Linux
# This script installs Crossplane and sets up the Astra platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CROSSPLANE_VERSION="1.14.0"
AZURE_PROVIDER_VERSION="v0.36.0"
NAMESPACE="crossplane-system"
ASTRA_NAMESPACE_PREFIX="astra"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed. Please install helm first."
        exit 1
    fi
    
    # Check if Minikube or Docker Desktop is running
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Kubernetes cluster is not accessible. Please start Minikube (minikube start) or Docker Desktop."
        exit 1
    fi
    
    # Display cluster context
    CURRENT_CONTEXT=$(kubectl config current-context)
    log_info "Using Kubernetes context: $CURRENT_CONTEXT"
    
    log_success "Prerequisites check passed"
}

# Install Crossplane
install_crossplane() {
    log_info "Installing Crossplane..."
    
    # Add Crossplane Helm repository
    helm repo add crossplane-stable https://charts.crossplane.io/stable
    helm repo update
    
    # Create namespace
    kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Crossplane
    helm upgrade --install crossplane \
        crossplane-stable/crossplane \
        --namespace ${NAMESPACE} \
        --version ${CROSSPLANE_VERSION} \
        --wait
    
    log_success "Crossplane installed successfully"
}

# Install Azure Provider
install_azure_provider() {
    log_info "Installing Azure Provider..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure
spec:
  package: xpkg.upbound.io/upbound/provider-azure-containerapp:${AZURE_PROVIDER_VERSION}
EOF

    # Wait for provider to be healthy
    log_info "Waiting for Azure provider to be ready..."
    kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-azure --timeout=300s
    
    log_success "Azure Provider installed successfully"
}

# Create ProviderConfig
create_provider_config() {
    log_info "Creating Azure ProviderConfig..."
    
    # Check if Azure credentials are set
    if [[ -z "$AZURE_CLIENT_ID" || -z "$AZURE_CLIENT_SECRET" || -z "$AZURE_TENANT_ID" || -z "$AZURE_SUBSCRIPTION_ID" ]]; then
        log_warn "Azure credentials not found in environment variables."
        log_info "Please set the following environment variables:"
        echo "  export AZURE_CLIENT_ID=<your-client-id>"
        echo "  export AZURE_CLIENT_SECRET=<your-client-secret>"
        echo "  export AZURE_TENANT_ID=<your-tenant-id>"
        echo "  export AZURE_SUBSCRIPTION_ID=<your-subscription-id>"
        log_info "Or create a service principal with: az ad sp create-for-rbac --role Contributor --scopes /subscriptions/<subscription-id>"
        exit 1
    fi
    
    # Create secret with Azure credentials
    kubectl create secret generic azure-secret -n ${NAMESPACE} \
        --from-literal=creds="{\"clientId\":\"${AZURE_CLIENT_ID}\",\"clientSecret\":\"${AZURE_CLIENT_SECRET}\",\"subscriptionId\":\"${AZURE_SUBSCRIPTION_ID}\",\"tenantId\":\"${AZURE_TENANT_ID}\"}" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create ProviderConfig
    cat <<EOF | kubectl apply -f -
apiVersion: azure.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: ${NAMESPACE}
      name: azure-secret
      key: creds
EOF

    log_success "Azure ProviderConfig created successfully"
}

# Install Astra Platform packages
install_astra_packages() {
    log_info "Installing Astra Platform packages..."
    
    # Apply all XRD definitions
    kubectl apply -f packages/resourcegroup/definition.yaml
    kubectl apply -f packages/managedidentity/definition.yaml
    kubectl apply -f packages/keyvault/definition.yaml
    kubectl apply -f packages/containerregistry/definition.yaml
    kubectl apply -f packages/storage/definition.yaml
    kubectl apply -f packages/containerapp/definition.yaml
    kubectl apply -f packages/platform/definition.yaml
    
    # Apply all Compositions
    kubectl apply -f packages/resourcegroup/composition.yaml
    kubectl apply -f packages/managedidentity/composition.yaml
    kubectl apply -f packages/keyvault/composition.yaml
    kubectl apply -f packages/containerregistry/composition.yaml
    kubectl apply -f packages/storage/composition.yaml
    kubectl apply -f packages/containerapp/composition.yaml
    kubectl apply -f packages/platform/composition.yaml
    
    # Wait for XRDs to be established
    log_info "Waiting for XRDs to be established..."
    kubectl wait --for=condition=Established xrd/xresourcegroups.astra.platform --timeout=60s
    kubectl wait --for=condition=Established xrd/xmanagedidentities.astra.platform --timeout=60s
    kubectl wait --for=condition=Established xrd/xkeyvaults.astra.platform --timeout=60s
    kubectl wait --for=condition=Established xrd/xcontainerregistries.astra.platform --timeout=60s
    kubectl wait --for=condition=Established xrd/xstorages.astra.platform --timeout=60s
    kubectl wait --for=condition=Established xrd/xcontainerapps.astra.platform --timeout=60s
    kubectl wait --for=condition=Established xrd/xplatforms.astra.platform --timeout=60s
    
    log_success "Astra Platform packages installed successfully"
}

# Create namespaces for environments
create_namespaces() {
    log_info "Creating environment namespaces..."
    
    kubectl create namespace ${ASTRA_NAMESPACE_PREFIX}-dev --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace ${ASTRA_NAMESPACE_PREFIX}-staging --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace ${ASTRA_NAMESPACE_PREFIX}-prod --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Environment namespaces created successfully"
}

# Main installation function
main() {
    log_info "Starting Astra Platform installation..."
    
    check_prerequisites
    install_crossplane
    install_azure_provider
    create_provider_config
    install_astra_packages
    create_namespaces
    
    log_success "Astra Platform installation completed successfully!"
    log_info "Next steps:"
    echo "  1. Update tenant ID in overlay files: overlays/*/platform-claim.yaml"
    echo "  2. Deploy to an environment: kubectl apply -k overlays/dev"
    echo "  3. Check status: kubectl get xplatform -n astra-dev"
}

# Run main function
main "$@"