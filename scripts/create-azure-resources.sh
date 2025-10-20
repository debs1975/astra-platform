#!/bin/bash
set -euo pipefail

################################################################################
# Azure Resources Creation Script
# 
# This script creates the Azure resources topology for the Astra Platform
# using Azure CLI commands. It follows the same structure as the Crossplane
# definitions but uses native Azure CLI for direct resource creation.
#
# Documentation:
#   For complete documentation, examples, and troubleshooting, see:
#   docs/operations/azure-resources-creation.md
#
# Usage:
#   ./scripts/create-azure-resources.sh <environment>
#
# Example:
#   ./scripts/create-azure-resources.sh dev
#   ./scripts/create-azure-resources.sh staging
#   ./scripts/create-azure-resources.sh prod
#
# Custom Resource Prefix:
#   RESOURCE_PREFIX=myapp ./scripts/create-azure-resources.sh dev
#   This will create resources like: myapp-dev-rg, myappdevacr, etc.
#
# Environment Variables:
#   RESOURCE_PREFIX          - Resource naming prefix (default: astra)
#   AZURE_LOCATION           - Azure region (default: centralindia)
#   AZURE_SUBSCRIPTION_ID    - Azure subscription ID (auto-detected)
#   CONTAINER_REGISTRY_SKU   - ACR SKU (default: Basic)
#   CONTAINER_APP_MAX_REPLICAS - Max replicas (default: 10)
#   ... and more (see CONFIGURATION VARIABLES section)
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check for required arguments
if [ $# -lt 1 ]; then
    log_error "Environment parameter is required"
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
    exit 1
fi

ENVIRONMENT=$1

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: dev, staging, prod"
    exit 1
fi

################################################################################
# CONFIGURATION VARIABLES
################################################################################

# Azure Configuration
export AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
export AZURE_TENANT_ID="${AZURE_TENANT_ID:-$(az account show --query tenantId -o tsv)}"
export AZURE_LOCATION="${AZURE_LOCATION:-centralindia}"

# Resource Naming Convention: {prefix}-{env}-{resource}
# You can override the prefix by setting RESOURCE_PREFIX environment variable
export RESOURCE_PREFIX="${RESOURCE_PREFIX:-astra}"
export RESOURCE_GROUP_NAME="${RESOURCE_PREFIX}-${ENVIRONMENT}-rg"

# Container Registry (no hyphens allowed)
export CONTAINER_REGISTRY_NAME="${RESOURCE_PREFIX}${ENVIRONMENT}acr"
export CONTAINER_REGISTRY_SKU="${CONTAINER_REGISTRY_SKU:-Basic}"

# Key Vault
export KEY_VAULT_NAME="${RESOURCE_PREFIX}-${ENVIRONMENT}-kv"
export KEY_VAULT_SKU="${KEY_VAULT_SKU:-standard}"

# Storage Account (no hyphens allowed)
export STORAGE_ACCOUNT_NAME="${RESOURCE_PREFIX}${ENVIRONMENT}sta"
export STORAGE_ACCOUNT_SKU="${STORAGE_ACCOUNT_SKU:-Standard_LRS}"
export STORAGE_ACCOUNT_KIND="${STORAGE_ACCOUNT_KIND:-StorageV2}"

# Managed Identity
export MANAGED_IDENTITY_NAME="${RESOURCE_PREFIX}-${ENVIRONMENT}-mi"

# Container Apps Environment
export CONTAINER_APPS_ENV_NAME="${RESOURCE_PREFIX}-${ENVIRONMENT}-cae"
export CONTAINER_APPS_ENV_TYPE="${CONTAINER_APPS_ENV_TYPE:-Consumption}"

# Container App
export CONTAINER_APP_NAME="${RESOURCE_PREFIX}-${ENVIRONMENT}-app"
export CONTAINER_IMAGE="${CONTAINER_IMAGE:-mcr.microsoft.com/azuredocs/containerapps-helloworld:latest}"
export CONTAINER_APP_CPU="${CONTAINER_APP_CPU:-0.5}"
export CONTAINER_APP_MEMORY="${CONTAINER_APP_MEMORY:-1.0Gi}"
export CONTAINER_APP_MIN_REPLICAS="${CONTAINER_APP_MIN_REPLICAS:-1}"
export CONTAINER_APP_MAX_REPLICAS="${CONTAINER_APP_MAX_REPLICAS:-10}"
export CONTAINER_APP_PORT="${CONTAINER_APP_PORT:-80}"

# Log Analytics Workspace (for Container Apps Environment)
export LOG_ANALYTICS_WORKSPACE_NAME="${RESOURCE_PREFIX}-${ENVIRONMENT}-law"

# Tags
export TAG_ENVIRONMENT="$ENVIRONMENT"
export TAG_PROJECT="${RESOURCE_PREFIX}-platform"
export TAG_MANAGED_BY="azure-cli"
export TAG_CREATED_DATE="$(date +%Y-%m-%d)"

################################################################################
# DISPLAY CONFIGURATION
################################################################################

log_info "Azure Resources Creation Configuration"
echo "========================================"
echo "Resource Prefix:          $RESOURCE_PREFIX"
echo "Environment:              $ENVIRONMENT"
echo "Azure Subscription:       $AZURE_SUBSCRIPTION_ID"
echo "Azure Location:           $AZURE_LOCATION"
echo ""
echo "Resource Group:           $RESOURCE_GROUP_NAME"
echo "Container Registry:       $CONTAINER_REGISTRY_NAME"
echo "Key Vault:                $KEY_VAULT_NAME"
echo "Storage Account:          $STORAGE_ACCOUNT_NAME"
echo "Managed Identity:         $MANAGED_IDENTITY_NAME"
echo "Container Apps Env:       $CONTAINER_APPS_ENV_NAME"
echo "Container App:            $CONTAINER_APP_NAME"
echo "Log Analytics Workspace:  $LOG_ANALYTICS_WORKSPACE_NAME"
echo "========================================"
echo ""

# Confirmation prompt
read -p "Do you want to proceed with resource creation? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    log_warning "Resource creation cancelled by user"
    exit 0
fi

################################################################################
# VERIFY AZURE CLI LOGIN
################################################################################

log_info "Verifying Azure CLI login..."
if ! az account show &> /dev/null; then
    log_error "Not logged in to Azure CLI"
    log_info "Please run: az login"
    exit 1
fi

log_success "Azure CLI authenticated"
log_info "Using subscription: $(az account show --query name -o tsv)"

################################################################################
# STEP 1: CREATE RESOURCE GROUP
################################################################################

log_info "Step 1/8: Creating Resource Group..."

az group create \
    --name "$RESOURCE_GROUP_NAME" \
    --location "$AZURE_LOCATION" \
    --tags \
        environment="$TAG_ENVIRONMENT" \
        project="$TAG_PROJECT" \
        managed-by="$TAG_MANAGED_BY" \
        created-date="$TAG_CREATED_DATE" \
    --output table

if [ $? -eq 0 ]; then
    log_success "Resource Group created: $RESOURCE_GROUP_NAME"
else
    log_error "Failed to create Resource Group"
    exit 1
fi

################################################################################
# STEP 2: CREATE MANAGED IDENTITY
################################################################################

log_info "Step 2/8: Creating Managed Identity..."

az identity create \
    --name "$MANAGED_IDENTITY_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$AZURE_LOCATION" \
    --tags \
        environment="$TAG_ENVIRONMENT" \
        project="$TAG_PROJECT" \
    --output table

if [ $? -eq 0 ]; then
    log_success "Managed Identity created: $MANAGED_IDENTITY_NAME"
    
    # Get the identity details
    IDENTITY_ID=$(az identity show \
        --name "$MANAGED_IDENTITY_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query id -o tsv)
    
    IDENTITY_PRINCIPAL_ID=$(az identity show \
        --name "$MANAGED_IDENTITY_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query principalId -o tsv)
    
    IDENTITY_CLIENT_ID=$(az identity show \
        --name "$MANAGED_IDENTITY_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query clientId -o tsv)
    
    log_info "Identity ID: $IDENTITY_ID"
    log_info "Principal ID: $IDENTITY_PRINCIPAL_ID"
    log_info "Client ID: $IDENTITY_CLIENT_ID"
else
    log_error "Failed to create Managed Identity"
    exit 1
fi

################################################################################
# STEP 3: CREATE CONTAINER REGISTRY
################################################################################

log_info "Step 3/8: Creating Container Registry..."

az acr create \
    --name "$CONTAINER_REGISTRY_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$AZURE_LOCATION" \
    --sku "$CONTAINER_REGISTRY_SKU" \
    --admin-enabled false \
    --tags \
        environment="$TAG_ENVIRONMENT" \
        project="$TAG_PROJECT" \
    --output table

if [ $? -eq 0 ]; then
    log_success "Container Registry created: $CONTAINER_REGISTRY_NAME"
    
    # Get the registry login server
    ACR_LOGIN_SERVER=$(az acr show \
        --name "$CONTAINER_REGISTRY_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query loginServer -o tsv)
    
    log_info "ACR Login Server: $ACR_LOGIN_SERVER"
    
    # Assign AcrPull role to Managed Identity
    log_info "Assigning AcrPull role to Managed Identity..."
    az role assignment create \
        --assignee "$IDENTITY_PRINCIPAL_ID" \
        --role AcrPull \
        --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.ContainerRegistry/registries/$CONTAINER_REGISTRY_NAME" \
        --output none
    
    log_success "AcrPull role assigned to Managed Identity"
else
    log_error "Failed to create Container Registry"
    exit 1
fi

################################################################################
# STEP 4: CREATE KEY VAULT
################################################################################

log_info "Step 4/8: Creating Key Vault..."

az keyvault create \
    --name "$KEY_VAULT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$AZURE_LOCATION" \
    --sku "$KEY_VAULT_SKU" \
    --enabled-for-deployment true \
    --enabled-for-disk-encryption false \
    --enabled-for-template-deployment true \
    --enable-rbac-authorization true \
    --tags \
        environment="$TAG_ENVIRONMENT" \
        project="$TAG_PROJECT" \
    --output table

if [ $? -eq 0 ]; then
    log_success "Key Vault created: $KEY_VAULT_NAME"
    
    # Get Key Vault URI
    KEY_VAULT_URI=$(az keyvault show \
        --name "$KEY_VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query properties.vaultUri -o tsv)
    
    log_info "Key Vault URI: $KEY_VAULT_URI"
    
    # Assign Key Vault Secrets User role to Managed Identity
    log_info "Assigning Key Vault Secrets User role to Managed Identity..."
    az role assignment create \
        --assignee "$IDENTITY_PRINCIPAL_ID" \
        --role "Key Vault Secrets User" \
        --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.KeyVault/vaults/$KEY_VAULT_NAME" \
        --output none
    
    log_success "Key Vault Secrets User role assigned to Managed Identity"
else
    log_error "Failed to create Key Vault"
    exit 1
fi

################################################################################
# STEP 5: CREATE STORAGE ACCOUNT
################################################################################

log_info "Step 5/8: Creating Storage Account..."

az storage account create \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$AZURE_LOCATION" \
    --sku "$STORAGE_ACCOUNT_SKU" \
    --kind "$STORAGE_ACCOUNT_KIND" \
    --access-tier Hot \
    --allow-blob-public-access false \
    --min-tls-version TLS1_2 \
    --tags \
        environment="$TAG_ENVIRONMENT" \
        project="$TAG_PROJECT" \
    --output table

if [ $? -eq 0 ]; then
    log_success "Storage Account created: $STORAGE_ACCOUNT_NAME"
    
    # Create a blob container
    log_info "Creating blob container..."
    az storage container create \
        --name "data" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --auth-mode login \
        --output none
    
    log_success "Blob container 'data' created"
    
    # Assign Storage Blob Data Contributor role to Managed Identity
    log_info "Assigning Storage Blob Data Contributor role to Managed Identity..."
    az role assignment create \
        --assignee "$IDENTITY_PRINCIPAL_ID" \
        --role "Storage Blob Data Contributor" \
        --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME" \
        --output none
    
    log_success "Storage Blob Data Contributor role assigned to Managed Identity"
else
    log_error "Failed to create Storage Account"
    exit 1
fi

################################################################################
# STEP 6: CREATE LOG ANALYTICS WORKSPACE
################################################################################

log_info "Step 6/8: Creating Log Analytics Workspace..."

az monitor log-analytics workspace create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --workspace-name "$LOG_ANALYTICS_WORKSPACE_NAME" \
    --location "$AZURE_LOCATION" \
    --tags \
        environment="$TAG_ENVIRONMENT" \
        project="$TAG_PROJECT" \
    --output table

if [ $? -eq 0 ]; then
    log_success "Log Analytics Workspace created: $LOG_ANALYTICS_WORKSPACE_NAME"
    
    # Get workspace details
    LOG_ANALYTICS_WORKSPACE_ID=$(az monitor log-analytics workspace show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --workspace-name "$LOG_ANALYTICS_WORKSPACE_NAME" \
        --query customerId -o tsv)
    
    LOG_ANALYTICS_WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --workspace-name "$LOG_ANALYTICS_WORKSPACE_NAME" \
        --query primarySharedKey -o tsv)
    
    log_info "Workspace ID: $LOG_ANALYTICS_WORKSPACE_ID"
else
    log_error "Failed to create Log Analytics Workspace"
    exit 1
fi

################################################################################
# STEP 7: CREATE CONTAINER APPS ENVIRONMENT
################################################################################

log_info "Step 7/8: Creating Container Apps Environment..."

az containerapp env create \
    --name "$CONTAINER_APPS_ENV_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$AZURE_LOCATION" \
    --logs-workspace-id "$LOG_ANALYTICS_WORKSPACE_ID" \
    --logs-workspace-key "$LOG_ANALYTICS_WORKSPACE_KEY" \
    --tags \
        environment="$TAG_ENVIRONMENT" \
        project="$TAG_PROJECT" \
    --output table

if [ $? -eq 0 ]; then
    log_success "Container Apps Environment created: $CONTAINER_APPS_ENV_NAME"
    
    # Get environment details
    CONTAINER_APPS_ENV_ID=$(az containerapp env show \
        --name "$CONTAINER_APPS_ENV_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query id -o tsv)
    
    log_info "Environment ID: $CONTAINER_APPS_ENV_ID"
else
    log_error "Failed to create Container Apps Environment"
    exit 1
fi

################################################################################
# STEP 8: CREATE CONTAINER APP
################################################################################

log_info "Step 8/8: Creating Container App..."

az containerapp create \
    --name "$CONTAINER_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --environment "$CONTAINER_APPS_ENV_NAME" \
    --image "$CONTAINER_IMAGE" \
    --target-port "$CONTAINER_APP_PORT" \
    --ingress external \
    --cpu "$CONTAINER_APP_CPU" \
    --memory "$CONTAINER_APP_MEMORY" \
    --min-replicas "$CONTAINER_APP_MIN_REPLICAS" \
    --max-replicas "$CONTAINER_APP_MAX_REPLICAS" \
    --user-assigned "$IDENTITY_ID" \
    --registry-server "$ACR_LOGIN_SERVER" \
    --registry-identity "$IDENTITY_ID" \
    --env-vars \
        "AZURE_CLIENT_ID=$IDENTITY_CLIENT_ID" \
        "KEY_VAULT_URI=$KEY_VAULT_URI" \
        "STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME" \
    --tags \
        environment="$TAG_ENVIRONMENT" \
        project="$TAG_PROJECT" \
    --output table

if [ $? -eq 0 ]; then
    log_success "Container App created: $CONTAINER_APP_NAME"
    
    # Get the application URL
    APP_URL=$(az containerapp show \
        --name "$CONTAINER_APP_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query properties.configuration.ingress.fqdn -o tsv)
    
    log_success "Container App URL: https://$APP_URL"
else
    log_error "Failed to create Container App"
    exit 1
fi

################################################################################
# SUMMARY
################################################################################

echo ""
log_success "=============================================="
log_success "  Azure Resources Creation Completed!"
log_success "=============================================="
echo ""
echo "Environment: $ENVIRONMENT"
echo ""
echo "Created Resources:"
echo "  ✓ Resource Group:         $RESOURCE_GROUP_NAME"
echo "  ✓ Managed Identity:       $MANAGED_IDENTITY_NAME"
echo "  ✓ Container Registry:     $CONTAINER_REGISTRY_NAME ($ACR_LOGIN_SERVER)"
echo "  ✓ Key Vault:              $KEY_VAULT_NAME"
echo "  ✓ Storage Account:        $STORAGE_ACCOUNT_NAME"
echo "  ✓ Log Analytics:          $LOG_ANALYTICS_WORKSPACE_NAME"
echo "  ✓ Container Apps Env:     $CONTAINER_APPS_ENV_NAME"
echo "  ✓ Container App:          $CONTAINER_APP_NAME"
echo ""
echo "Application URL: https://$APP_URL"
echo ""
echo "Next Steps:"
echo "  1. Visit the application URL to verify deployment"
echo "  2. Push your container image to ACR: az acr login --name $CONTAINER_REGISTRY_NAME"
echo "  3. Store secrets in Key Vault: az keyvault secret set --vault-name $KEY_VAULT_NAME"
echo "  4. View logs: az containerapp logs show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP_NAME"
echo ""
log_info "To delete all resources, run:"
echo "  az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait"
echo ""
log_success "=============================================="
