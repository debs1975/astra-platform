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
CROSSPLANE_NAMESPACE="crossplane-system"
ASTRA_NAMESPACE_PREFIX="astra-ns"
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
# Install Docker on macOS
install_docker_macos() {
    log_info "Installing Docker for Mac..."
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew is not installed. Please install Homebrew first: https://brew.sh/"
        exit 1
    fi
    # Install Docker using Homebrew Cask
    brew install --cask docker
    log_success "Docker installed successfully"
}

# Start Docker on macOS
start_docker_macos() {
    log_info "Starting Docker..."
    open -a Docker
    # Wait until Docker is running
    until docker info &> /dev/null; do
        echo "Waiting for Docker to start..."
        sleep 5
    done
    log_success "Docker is running"
}   

# check if Docker is running
check_docker_running() {
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Install Minikube on macOS
install_minikube_macos() {
    log_info "Installing Minikube..."
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew is not installed. Please install Homebrew first: https://brew.sh/"
        exit 1
    fi
    # Install Minikube using Homebrew
    brew install minikube
    log_success "Minikube installed successfully"
}

# Start Minikube
start_minikube() {
    log_info "Starting Minikube..."
    minikube start --driver=docker
    log_success "Minikube started successfully"
}   

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        # Install kubectl
        
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
    kubectl create namespace ${CROSSPLANE_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    # Install Crossplane
    helm upgrade --install crossplane \
        crossplane-stable/crossplane \
        --namespace ${CROSSPLANE_NAMESPACE} \
        --version ${CROSSPLANE_VERSION} \
        --wait
    log_success "Crossplane installed successfully"
}

# Install Azure Provider
install_azure_provider() {
    log_info "Installing Azure Provider..."
    kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure
spec:
  package: xpkg.upbound.io/upbound/provider-azure:${AZURE_PROVIDER_VERSION}
EOF
}   

