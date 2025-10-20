#!/bin/bash

# Astra Platform Secret Management Script for macOS/Linux
# This script manages Azure secrets and configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="crossplane-system"

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

# Show usage
show_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  create-sp [--name <name>] [--scope <scope>]  Create Azure service principal"
    echo "  set-creds --client-id <id> --client-secret <secret> --tenant-id <id> --subscription-id <id>"
    echo "            Set Azure credentials from parameters"
    echo "  set-creds-file --file <path>                 Set Azure credentials from JSON file"
    echo "  get-creds                                    Display current Azure credentials (masked)"
    echo "  update-secret                                Update Kubernetes secret with current env vars"
    echo "  test-connection                              Test Azure connection"
    echo "  rotate-secret                                Rotate service principal secret"
    echo "  cleanup                                      Remove all secrets"
    echo ""
    echo "Options:"
    echo "  --help                Show this help message"
}

# Create Azure service principal
create_service_principal() {
    local sp_name="$1"
    local scope="$2"
    
    if [[ -z "$sp_name" ]]; then
        sp_name="astra-platform-sp-$(date +%s)"
    fi
    
    if [[ -z "$scope" ]]; then
        # Get current subscription ID
        local subscription_id
        subscription_id=$(az account show --query id -o tsv 2>/dev/null || echo "")
        if [[ -z "$subscription_id" ]]; then
            log_error "Unable to get subscription ID. Please run 'az login' first."
            exit 1
        fi
        scope="/subscriptions/$subscription_id"
    fi
    
    log_info "Creating service principal: $sp_name"
    log_info "Scope: $scope"
    
    # Create service principal
    local sp_output
    sp_output=$(az ad sp create-for-rbac \
        --name "$sp_name" \
        --role "Contributor" \
        --scopes "$scope" \
        --output json)
    
    if [[ $? -eq 0 ]]; then
        log_success "Service principal created successfully"
        
        # Extract credentials
        local client_id
        local client_secret
        local tenant_id
        local subscription_id
        
        client_id=$(echo "$sp_output" | jq -r .appId)
        client_secret=$(echo "$sp_output" | jq -r .password)
        tenant_id=$(echo "$sp_output" | jq -r .tenant)
        subscription_id=$(az account show --query id -o tsv)
        
        # Set environment variables
        export AZURE_CLIENT_ID="$client_id"
        export AZURE_CLIENT_SECRET="$client_secret"
        export AZURE_TENANT_ID="$tenant_id"
        export AZURE_SUBSCRIPTION_ID="$subscription_id"
        
        echo ""
        log_info "Service principal credentials:"
        echo "export AZURE_CLIENT_ID=\"$client_id\""
        echo "export AZURE_CLIENT_SECRET=\"$client_secret\""
        echo "export AZURE_TENANT_ID=\"$tenant_id\""
        echo "export AZURE_SUBSCRIPTION_ID=\"$subscription_id\""
        echo ""
        log_info "Save these credentials securely and set them in your environment."
        
        # Update Kubernetes secret
        update_kubernetes_secret
    else
        log_error "Failed to create service principal"
        exit 1
    fi
}

# Set credentials from parameters
set_credentials() {
    local client_id="$1"
    local client_secret="$2"
    local tenant_id="$3"
    local subscription_id="$4"
    
    if [[ -z "$client_id" || -z "$client_secret" || -z "$tenant_id" || -z "$subscription_id" ]]; then
        log_error "All credential parameters are required: --client-id, --client-secret, --tenant-id, --subscription-id"
        exit 1
    fi
    
    export AZURE_CLIENT_ID="$client_id"
    export AZURE_CLIENT_SECRET="$client_secret"
    export AZURE_TENANT_ID="$tenant_id"
    export AZURE_SUBSCRIPTION_ID="$subscription_id"
    
    log_success "Azure credentials set successfully"
    update_kubernetes_secret
}

# Set credentials from file
set_credentials_from_file() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "File not found: $file_path"
        exit 1
    fi
    
    # Parse JSON file
    local client_id
    local client_secret
    local tenant_id
    local subscription_id
    
    client_id=$(jq -r .clientId "$file_path" 2>/dev/null || echo "")
    client_secret=$(jq -r .clientSecret "$file_path" 2>/dev/null || echo "")
    tenant_id=$(jq -r .tenantId "$file_path" 2>/dev/null || echo "")
    subscription_id=$(jq -r .subscriptionId "$file_path" 2>/dev/null || echo "")
    
    if [[ -z "$client_id" || -z "$client_secret" || -z "$tenant_id" || -z "$subscription_id" ]]; then
        log_error "Invalid JSON file format. Expected fields: clientId, clientSecret, tenantId, subscriptionId"
        exit 1
    fi
    
    export AZURE_CLIENT_ID="$client_id"
    export AZURE_CLIENT_SECRET="$client_secret"
    export AZURE_TENANT_ID="$tenant_id"
    export AZURE_SUBSCRIPTION_ID="$subscription_id"
    
    log_success "Azure credentials loaded from file successfully"
    update_kubernetes_secret
}

# Get current credentials (masked)
get_credentials() {
    log_info "Current Azure credentials:"
    echo "AZURE_CLIENT_ID: ${AZURE_CLIENT_ID:0:8}***"
    echo "AZURE_CLIENT_SECRET: ${AZURE_CLIENT_SECRET:0:4}***"
    echo "AZURE_TENANT_ID: ${AZURE_TENANT_ID:0:8}***"
    echo "AZURE_SUBSCRIPTION_ID: ${AZURE_SUBSCRIPTION_ID:0:8}***"
    
    # Check if secret exists in Kubernetes
    if kubectl get secret azure-secret -n "$NAMESPACE" &> /dev/null; then
        echo ""
        log_success "Azure secret exists in Kubernetes"
    else
        echo ""
        log_warn "Azure secret does not exist in Kubernetes"
    fi
}

# Update Kubernetes secret
update_kubernetes_secret() {
    if [[ -z "$AZURE_CLIENT_ID" || -z "$AZURE_CLIENT_SECRET" || -z "$AZURE_TENANT_ID" || -z "$AZURE_SUBSCRIPTION_ID" ]]; then
        log_error "Azure credentials not set in environment variables"
        exit 1
    fi
    
    log_info "Updating Kubernetes secret..."
    
    # Create JSON credentials
    local creds_json
    creds_json=$(jq -n \
        --arg clientId "$AZURE_CLIENT_ID" \
        --arg clientSecret "$AZURE_CLIENT_SECRET" \
        --arg subscriptionId "$AZURE_SUBSCRIPTION_ID" \
        --arg tenantId "$AZURE_TENANT_ID" \
        '{clientId: $clientId, clientSecret: $clientSecret, subscriptionId: $subscriptionId, tenantId: $tenantId}')
    
    # Create or update secret
    kubectl create secret generic azure-secret -n "$NAMESPACE" \
        --from-literal=creds="$creds_json" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Kubernetes secret updated successfully"
}

# Test Azure connection
test_connection() {
    log_info "Testing Azure connection..."
    
    # Check environment variables
    if [[ -z "$AZURE_CLIENT_ID" || -z "$AZURE_CLIENT_SECRET" || -z "$AZURE_TENANT_ID" || -z "$AZURE_SUBSCRIPTION_ID" ]]; then
        log_error "Azure credentials not set in environment variables"
        exit 1
    fi
    
    # Test authentication
    if az login --service-principal \
        --username "$AZURE_CLIENT_ID" \
        --password "$AZURE_CLIENT_SECRET" \
        --tenant "$AZURE_TENANT_ID" &> /dev/null; then
        
        log_success "Azure authentication successful"
        
        # Test subscription access
        local subscription_name
        subscription_name=$(az account show --query name -o tsv 2>/dev/null || echo "Unknown")
        log_info "Connected to subscription: $subscription_name"
        
        # Test resource group listing
        local rg_count
        rg_count=$(az group list --query "length(@)" -o tsv 2>/dev/null || echo "0")
        log_info "Found $rg_count resource groups"
        
    else
        log_error "Azure authentication failed"
        exit 1
    fi
}

# Rotate service principal secret
rotate_secret() {
    log_info "Rotating service principal secret..."
    
    if [[ -z "$AZURE_CLIENT_ID" ]]; then
        log_error "AZURE_CLIENT_ID not set"
        exit 1
    fi
    
    # Generate new password
    local new_password
    new_password=$(az ad sp credential reset \
        --id "$AZURE_CLIENT_ID" \
        --query password -o tsv)
    
    if [[ $? -eq 0 ]]; then
        export AZURE_CLIENT_SECRET="$new_password"
        log_success "Service principal secret rotated successfully"
        log_info "New secret: ${new_password:0:4}***"
        
        # Update Kubernetes secret
        update_kubernetes_secret
    else
        log_error "Failed to rotate service principal secret"
        exit 1
    fi
}

# Cleanup secrets
cleanup() {
    log_warn "This will remove all Azure secrets from Kubernetes. Are you sure? (y/N)"
    read -r confirmation
    
    if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
        log_info "Removing Azure secret from Kubernetes..."
        kubectl delete secret azure-secret -n "$NAMESPACE" 2>/dev/null || log_warn "Secret not found"
        log_success "Cleanup completed"
    else
        log_info "Cleanup cancelled"
    fi
}

# Main function
main() {
    local command=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            create-sp)
                command="create-sp"
                shift
                ;;
            set-creds)
                command="set-creds"
                shift
                ;;
            set-creds-file)
                command="set-creds-file"
                shift
                ;;
            get-creds)
                command="get-creds"
                shift
                ;;
            update-secret)
                command="update-secret"
                shift
                ;;
            test-connection)
                command="test-connection"
                shift
                ;;
            rotate-secret)
                command="rotate-secret"
                shift
                ;;
            cleanup)
                command="cleanup"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Execute command
    case $command in
        create-sp)
            local sp_name=""
            local scope=""
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --name)
                        sp_name="$2"
                        shift 2
                        ;;
                    --scope)
                        scope="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            create_service_principal "$sp_name" "$scope"
            ;;
        set-creds)
            local client_id=""
            local client_secret=""
            local tenant_id=""
            local subscription_id=""
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --client-id)
                        client_id="$2"
                        shift 2
                        ;;
                    --client-secret)
                        client_secret="$2"
                        shift 2
                        ;;
                    --tenant-id)
                        tenant_id="$2"
                        shift 2
                        ;;
                    --subscription-id)
                        subscription_id="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            set_credentials "$client_id" "$client_secret" "$tenant_id" "$subscription_id"
            ;;
        set-creds-file)
            local file_path=""
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --file)
                        file_path="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            set_credentials_from_file "$file_path"
            ;;
        get-creds)
            get_credentials
            ;;
        update-secret)
            update_kubernetes_secret
            ;;
        test-connection)
            test_connection
            ;;
        rotate-secret)
            rotate_secret
            ;;
        cleanup)
            cleanup
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"