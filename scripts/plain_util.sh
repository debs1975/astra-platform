# Install Docker

# Install Docker using Homebrew Cask
brew install --cask docker
log_success "Docker installed successfully"

# Start Docker from Mac command line
open -a Docker
# Wait until Docker is running
until docker info &> /dev/null; do
    echo "Waiting for Docker to start..."
    sleep 5
done
# Display Docker info
docker info

# Install Minikube
brew install minikube
log_success "Minikube installed successfully"

# Start minikube
minikube start --driver=docker
# Check minikube status
minikube status

# Add Crossplane Helm repo
CROSSPLANE_VERSION="2.0.2"
AZURE_PROVIDER_VERSION="v2.1.0"
CROSSPLANE_NAMESPACE="crossplane-system"

helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Install Crossplane with a specific namespace
log_info "Installing Crossplane..."
helm install crossplane --namespace "$NAMESPACE" --create-namespace crossplane-stable/crossplane --version "$CROSSPLANE_VERSION"

# Wait for Crossplane to be ready
kubectl wait --for=condition=Available deployment/crossplane -n "$NAMESPACE" --timeout=180s || {
    log_error "Crossplane installation timed out. Please check the status manually:"
    echo "  kubectl get pods -n $NAMESPACE"
    exit 1
}
# Check the version of Crossplane
kubectl get deployment crossplane -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].image}'
log_success "Crossplane version: $CROSSPLANE_VERSION"

# Install Azure Provider
log_info "Installing Azure Provider..."
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure-family
spec:
  package: xpkg.upbound.io/upbound/provider-family-azure:${AZURE_PROVIDER_VERSION}
EOF
# Wait for Azure Provider to be ready
log_info "Waiting for Azure Provider to be ready..."
kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-azure-family --timeout=300s
log_success "Azure Provider installed successfully"

# Create ProviderConfig for Azure Family