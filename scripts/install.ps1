# Astra Platform Installation Script for Windows (PowerShell)
# This script installs Crossplane and sets up the Astra platform

param(
    [switch]$SkipPrerequisites,
    [string]$CrossplaneVersion = "1.14.0",
    [string]$AzureProviderVersion = "v0.36.0"
)

# Configuration
$Namespace = "crossplane-system"
$AstraNamespacePrefix = "astra"

# Logging functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if kubectl is installed
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Error "kubectl is not installed. Please install kubectl first."
        exit 1
    }
    
    # Check if helm is installed
    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        Write-Error "helm is not installed. Please install helm first."
        exit 1
    }
    
    # Check if Kubernetes cluster is accessible
    try {
        kubectl cluster-info | Out-Null
    }
    catch {
        Write-Error "Kubernetes cluster is not accessible. Please start Minikube (minikube start) or Docker Desktop."
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
}

# Install Crossplane
function Install-Crossplane {
    Write-Info "Installing Crossplane..."
    
    # Add Crossplane Helm repository
    helm repo add crossplane-stable https://charts.crossplane.io/stable
    helm repo update
    
    # Create namespace
    kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Crossplane
    helm upgrade --install crossplane `
        crossplane-stable/crossplane `
        --namespace $Namespace `
        --version $CrossplaneVersion `
        --wait
    
    Write-Success "Crossplane installed successfully"
}

# Install Azure Provider
function Install-AzureProvider {
    Write-Info "Installing Azure Provider..."
    
    $providerYaml = @"
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure
spec:
  package: xpkg.upbound.io/upbound/provider-azure-containerapp:$AzureProviderVersion
"@

    $providerYaml | kubectl apply -f -
    
    # Wait for provider to be healthy
    Write-Info "Waiting for Azure provider to be ready..."
    kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-azure --timeout=300s
    
    Write-Success "Azure Provider installed successfully"
}

# Create ProviderConfig
function New-ProviderConfig {
    Write-Info "Creating Azure ProviderConfig..."
    
    # Check if Azure credentials are set
    $clientId = $env:AZURE_CLIENT_ID
    $clientSecret = $env:AZURE_CLIENT_SECRET
    $tenantId = $env:AZURE_TENANT_ID
    $subscriptionId = $env:AZURE_SUBSCRIPTION_ID
    
    if (-not $clientId -or -not $clientSecret -or -not $tenantId -or -not $subscriptionId) {
        Write-Warning "Azure credentials not found in environment variables."
        Write-Info "Please set the following environment variables:"
        Write-Host "  `$env:AZURE_CLIENT_ID = '<your-client-id>'"
        Write-Host "  `$env:AZURE_CLIENT_SECRET = '<your-client-secret>'"
        Write-Host "  `$env:AZURE_TENANT_ID = '<your-tenant-id>'"
        Write-Host "  `$env:AZURE_SUBSCRIPTION_ID = '<your-subscription-id>'"
        Write-Info "Or create a service principal with: az ad sp create-for-rbac --role Contributor --scopes /subscriptions/<subscription-id>"
        exit 1
    }
    
    # Create secret with Azure credentials
    $creds = @{
        clientId = $clientId
        clientSecret = $clientSecret
        subscriptionId = $subscriptionId
        tenantId = $tenantId
    } | ConvertTo-Json -Compress
    
    kubectl create secret generic azure-secret -n $Namespace `
        --from-literal=creds="$creds" `
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create ProviderConfig
    $providerConfigYaml = @"
apiVersion: azure.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: $Namespace
      name: azure-secret
      key: creds
"@

    $providerConfigYaml | kubectl apply -f -
    
    Write-Success "Azure ProviderConfig created successfully"
}

# Install Astra Platform packages
function Install-AstraPackages {
    Write-Info "Installing Astra Platform packages..."
    
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
    Write-Info "Waiting for XRDs to be established..."
    kubectl wait --for=condition=Established xrd/xresourcegroups.astra.platform --timeout=60s
    kubectl wait --for=condition=Established xrd/xmanagedidentities.astra.platform --timeout=60s
    kubectl wait --for=condition=Established xrd/xkeyvaults.astra.platform --timeout=60s
    kubectl wait --for=condition=Established xrd/xcontainerregistries.astra.platform --timeout=60s
    kubectl wait --for=condition=Established xrd/xstorages.astra.platform --timeout=60s
    kubectl wait --for=condition=Established xrd/xcontainerapps.astra.platform --timeout=60s
    kubectl wait --for=condition=Established xrd/xplatforms.astra.platform --timeout=60s
    
    Write-Success "Astra Platform packages installed successfully"
}

# Create namespaces for environments
function New-Namespaces {
    Write-Info "Creating environment namespaces..."
    
    kubectl create namespace "$AstraNamespacePrefix-dev" --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace "$AstraNamespacePrefix-staging" --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace "$AstraNamespacePrefix-prod" --dry-run=client -o yaml | kubectl apply -f -
    
    Write-Success "Environment namespaces created successfully"
}

# Main installation function
function Install-AstraPlatform {
    Write-Info "Starting Astra Platform installation..."
    
    if (-not $SkipPrerequisites) {
        Test-Prerequisites
    }
    
    Install-Crossplane
    Install-AzureProvider
    New-ProviderConfig
    Install-AstraPackages
    New-Namespaces
    
    Write-Success "Astra Platform installation completed successfully!"
    Write-Info "Next steps:"
    Write-Host "  1. Update tenant ID in overlay files: overlays/*/platform-claim.yaml"
    Write-Host "  2. Deploy to an environment: kubectl apply -k overlays/dev"
    Write-Host "  3. Check status: kubectl get xplatform -n astra-dev"
}

# Run main function
Install-AstraPlatform