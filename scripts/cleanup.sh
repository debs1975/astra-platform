#!/bin/bash

# Astra Platform Cleanup Script for macOS/Linux
# This script removes Crossplane and all Astra platform resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="crossplane-system"
ASTRA_NAMESPACES=("astra-dev" "astra-staging" "astra-prod")

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
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --force              Skip confirmation prompts"
    echo "  --keep-crossplane    Don't remove Crossplane itself"
    echo "  --azure-only         Only remove Azure resources (keep platform)"
    echo "  --help               Show this help message"
}

# Confirm action
confirm_action() {
    local message="$1"
    local force="$2"
    
    if [[ "$force" == "true" ]]; then
        return 0
    fi
    
    log_warn "$message"
    read -p "Are you sure? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled"
        exit 0
    fi
}

# Remove platform claims
remove_platform_claims() {
    log_info "Removing platform claims..."
    
    for namespace in "${ASTRA_NAMESPACES[@]}"; do
        if kubectl get namespace "$namespace" &> /dev/null; then
            log_info "Removing platform claims in $namespace"
            kubectl delete xplatform --all -n "$namespace" --ignore-not-found=true
        fi
    done
    
    log_success "Platform claims removed"
}

# Remove managed resources
remove_managed_resources() {
    log_info "Removing managed resources..."
    
    # Get all managed resources created by Astra platform
    local managed_resources
    managed_resources=$(kubectl get managedresources.pkg.crossplane.io --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null | grep -E "astra-(dev|staging|prod)" || echo "")
    
    if [[ -n "$managed_resources" ]]; then
        echo "$managed_resources" | while read -r resource; do
            if [[ -n "$resource" ]]; then
                log_info "Removing managed resource: $resource"
                kubectl delete managedresource.pkg.crossplane.io "$resource" --ignore-not-found=true
            fi
        done
    else
        log_info "No managed resources found"
    fi
    
    log_success "Managed resources cleanup completed"
}

# Remove compositions
remove_compositions() {
    log_info "Removing Astra compositions..."
    
    kubectl delete composition xresourcegroups.astra.platform --ignore-not-found=true
    kubectl delete composition xmanagedidentities.astra.platform --ignore-not-found=true
    kubectl delete composition xkeyvaults.astra.platform --ignore-not-found=true
    kubectl delete composition xcontainerregistries.astra.platform --ignore-not-found=true
    kubectl delete composition xstorages.astra.platform --ignore-not-found=true
    kubectl delete composition xcontainerapps.astra.platform --ignore-not-found=true
    kubectl delete composition xplatforms.astra.platform --ignore-not-found=true
    
    log_success "Compositions removed"
}

# Remove XRDs
remove_xrds() {
    log_info "Removing Astra XRDs..."
    
    kubectl delete xrd xresourcegroups.astra.platform --ignore-not-found=true
    kubectl delete xrd xmanagedidentities.astra.platform --ignore-not-found=true
    kubectl delete xrd xkeyvaults.astra.platform --ignore-not-found=true
    kubectl delete xrd xcontainerregistries.astra.platform --ignore-not-found=true
    kubectl delete xrd xstorages.astra.platform --ignore-not-found=true
    kubectl delete xrd xcontainerapps.astra.platform --ignore-not-found=true
    kubectl delete xrd xplatforms.astra.platform --ignore-not-found=true
    
    log_success "XRDs removed"
}

# Remove Azure provider
remove_azure_provider() {
    log_info "Removing Azure provider..."
    
    # Remove ProviderConfig
    kubectl delete providerconfig.azure.upbound.io default --ignore-not-found=true
    
    # Remove Provider
    kubectl delete provider.pkg.crossplane.io provider-azure --ignore-not-found=true
    
    # Remove secrets
    kubectl delete secret azure-secret -n "$NAMESPACE" --ignore-not-found=true
    
    log_success "Azure provider removed"
}

# Remove namespaces
remove_namespaces() {
    log_info "Removing Astra namespaces..."
    
    for namespace in "${ASTRA_NAMESPACES[@]}"; do
        if kubectl get namespace "$namespace" &> /dev/null; then
            log_info "Removing namespace: $namespace"
            kubectl delete namespace "$namespace" --ignore-not-found=true
        fi
    done
    
    log_success "Namespaces removed"
}

# Remove Crossplane
remove_crossplane() {
    log_info "Removing Crossplane..."
    
    # Remove Crossplane using Helm
    if helm list -n "$NAMESPACE" | grep -q crossplane; then
        helm uninstall crossplane -n "$NAMESPACE"
    fi
    
    # Remove namespace
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
    
    log_success "Crossplane removed"
}

# Wait for resources to be deleted
wait_for_deletion() {
    log_info "Waiting for resources to be fully deleted..."
    
    # Wait for managed resources to be deleted
    local timeout=300
    local elapsed=0
    
    while [[ $elapsed -lt $timeout ]]; do
        local remaining
        remaining=$(kubectl get managedresources.pkg.crossplane.io --no-headers 2>/dev/null | grep -E "astra-(dev|staging|prod)" | wc -l || echo "0")
        
        if [[ "$remaining" -eq 0 ]]; then
            log_success "All managed resources have been deleted"
            return 0
        fi
        
        log_info "Waiting for $remaining managed resources to be deleted..."
        sleep 10
        elapsed=$((elapsed + 10))
    done
    
    log_warn "Timeout waiting for all resources to be deleted. Some resources may still exist in Azure."
}

# Main function
main() {
    local force="false"
    local keep_crossplane="false"
    local azure_only="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force="true"
                shift
                ;;
            --keep-crossplane)
                keep_crossplane="true"
                shift
                ;;
            --azure-only)
                azure_only="true"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Confirm cleanup
    if [[ "$azure_only" == "true" ]]; then
        confirm_action "This will remove all Azure resources created by Astra platform." "$force"
        
        remove_platform_claims
        wait_for_deletion
        remove_managed_resources
        
    elif [[ "$keep_crossplane" == "true" ]]; then
        confirm_action "This will remove all Astra platform resources but keep Crossplane." "$force"
        
        remove_platform_claims
        wait_for_deletion
        remove_managed_resources
        remove_compositions
        remove_xrds
        remove_azure_provider
        remove_namespaces
        
    else
        confirm_action "This will remove Crossplane and all Astra platform resources." "$force"
        
        remove_platform_claims
        wait_for_deletion
        remove_managed_resources
        remove_compositions
        remove_xrds
        remove_azure_provider
        remove_namespaces
        remove_crossplane
    fi
    
    log_success "Cleanup completed successfully!"
    
    if [[ "$azure_only" != "true" ]]; then
        echo ""
        log_info "Manual cleanup steps (if needed):"
        echo "  1. Check for remaining Azure resources in the Azure portal"
        echo "  2. Remove any remaining resource groups starting with 'astra-'"
        echo "  3. Clean up service principals if no longer needed"
    fi
}

# Run main function
main "$@"