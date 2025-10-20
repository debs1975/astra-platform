#!/bin/bash

# Astra Platform Deployment Script for macOS/Linux
# This script deploys applications to different environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VALID_ENVIRONMENTS=("dev" "staging" "prod")
NAMESPACE_PREFIX="astra"

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
    echo "Usage: $0 <environment> [options]"
    echo ""
    echo "Environments:"
    echo "  dev      Deploy to development environment"
    echo "  staging  Deploy to staging environment"
    echo "  prod     Deploy to production environment"
    echo ""
    echo "Options:"
    echo "  --image <image>     Container image to deploy"
    echo "  --tenant <id>       Azure tenant ID"
    echo "  --dry-run          Show what would be deployed without applying"
    echo "  --wait             Wait for deployment to be ready"
    echo "  --timeout <sec>    Timeout for wait operation (default: 600s)"
    echo "  --help             Show this help message"
}

# Validate environment
validate_environment() {
    local env="$1"
    
    for valid_env in "${VALID_ENVIRONMENTS[@]}"; do
        if [[ "$env" == "$valid_env" ]]; then
            return 0
        fi
    done
    
    log_error "Invalid environment: $env"
    log_info "Valid environments: ${VALID_ENVIRONMENTS[*]}"
    exit 1
}

# Update tenant ID in platform claim
update_tenant_id() {
    local env="$1"
    local tenant_id="$2"
    local platform_claim="overlays/$env/platform-claim.yaml"
    
    if [[ -n "$tenant_id" ]]; then
        log_info "Updating tenant ID in $platform_claim"
        sed -i.bak "s/YOUR_TENANT_ID/$tenant_id/g" "$platform_claim"
        rm "$platform_claim.bak"
    fi
}

# Update container image
update_container_image() {
    local env="$1"
    local image="$2"
    local platform_claim="overlays/$env/platform-claim.yaml"
    
    if [[ -n "$image" ]]; then
        log_info "Updating container image in $platform_claim"
        sed -i.bak "s|containerImage:.*|containerImage: \"$image\"|g" "$platform_claim"
        rm "$platform_claim.bak"
    fi
}

# Deploy to environment
deploy_environment() {
    local env="$1"
    local dry_run="$2"
    local wait_flag="$3"
    local timeout="$4"
    
    local namespace="${NAMESPACE_PREFIX}-${env}"
    
    log_info "Deploying to $env environment (namespace: $namespace)"
    
    # Check if namespace exists
    if ! kubectl get namespace "$namespace" &> /dev/null; then
        log_error "Namespace $namespace does not exist. Please run install.sh first."
        exit 1
    fi
    
    # Apply the overlay
    if [[ "$dry_run" == "true" ]]; then
        log_info "Dry run - showing what would be deployed:"
        kubectl apply -k "overlays/$env" --dry-run=client
    else
        kubectl apply -k "overlays/$env"
        log_success "Deployment applied successfully"
        
        if [[ "$wait_flag" == "true" ]]; then
            log_info "Waiting for platform to be ready (timeout: ${timeout}s)..."
            kubectl wait --for=condition=Ready xplatform -n "$namespace" --timeout="${timeout}s" || {
                log_warn "Timeout waiting for platform to be ready. Check status manually:"
                echo "  kubectl get xplatform -n $namespace"
                echo "  kubectl describe xplatform -n $namespace"
                exit 1
            }
            log_success "Platform is ready!"
        fi
    fi
}

# Show deployment status
show_status() {
    local env="$1"
    local namespace="${NAMESPACE_PREFIX}-${env}"
    
    log_info "Deployment status for $env environment:"
    echo ""
    
    # Check if platform exists
    if kubectl get xplatform -n "$namespace" &> /dev/null; then
        echo "Platform Status:"
        kubectl get xplatform -n "$namespace" -o wide
        echo ""
        
        echo "Platform Details:"
        kubectl describe xplatform -n "$namespace"
        echo ""
        
        echo "Related Resources:"
        kubectl get managedresources.pkg.crossplane.io --no-headers | grep "$namespace" || echo "No managed resources found"
    else
        log_warn "No platform deployment found in $namespace namespace"
    fi
}

# Get platform URLs
get_urls() {
    local env="$1"
    local namespace="${NAMESPACE_PREFIX}-${env}"
    
    log_info "Getting application URLs for $env environment:"
    
    # Get the platform status
    local app_url
    app_url=$(kubectl get xplatform -n "$namespace" -o jsonpath='{.status.applicationUrl}' 2>/dev/null || echo "")
    
    if [[ -n "$app_url" ]]; then
        echo "Application URL: https://$app_url"
    else
        log_warn "Application URL not yet available. Deployment may still be in progress."
    fi
}

# Main function
main() {
    local environment=""
    local container_image=""
    local tenant_id=""
    local dry_run="false"
    local wait_flag="false"
    local timeout="600"
    local show_status_flag="false"
    local get_urls_flag="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_usage
                exit 0
                ;;
            --image)
                container_image="$2"
                shift 2
                ;;
            --tenant)
                tenant_id="$2"
                shift 2
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            --wait)
                wait_flag="true"
                shift
                ;;
            --timeout)
                timeout="$2"
                shift 2
                ;;
            --status)
                show_status_flag="true"
                shift
                ;;
            --urls)
                get_urls_flag="true"
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$environment" ]]; then
                    environment="$1"
                else
                    log_error "Too many arguments"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate environment
    if [[ -z "$environment" ]]; then
        log_error "Environment is required"
        show_usage
        exit 1
    fi
    
    validate_environment "$environment"
    
    # Handle status and URLs commands
    if [[ "$show_status_flag" == "true" ]]; then
        show_status "$environment"
        exit 0
    fi
    
    if [[ "$get_urls_flag" == "true" ]]; then
        get_urls "$environment"
        exit 0
    fi
    
    # Update configuration if provided
    update_tenant_id "$environment" "$tenant_id"
    update_container_image "$environment" "$container_image"
    
    # Deploy
    deploy_environment "$environment" "$dry_run" "$wait_flag" "$timeout"
    
    # Show next steps
    if [[ "$dry_run" == "false" ]]; then
        echo ""
        log_info "Deployment completed. Next steps:"
        echo "  Check status: $0 $environment --status"
        echo "  Get URLs: $0 $environment --urls"
        echo "  View logs: kubectl logs -n ${NAMESPACE_PREFIX}-${environment} -l app.kubernetes.io/name=crossplane"
    fi
}

# Run main function
main "$@"