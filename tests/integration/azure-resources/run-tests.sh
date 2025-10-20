#!/bin/bash
set -euo pipefail

# Azure Resource Integration Test Runner
# Tests Azure resource creation, configuration, and lifecycle through Crossplane

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEST_DATA_DIR="$SCRIPT_DIR/test-data"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test configuration
TEST_NAMESPACE="${TEST_NAMESPACE:-astra-integration-test}"
TEST_RESOURCE_GROUP="${TEST_RESOURCE_GROUP:-astra-integration-test-rg}"
TEST_LOCATION="${TEST_LOCATION:-Central India}"
TEST_TIMEOUT="${TEST_TIMEOUT:-1800}"
CLEANUP_AFTER_TESTS="${CLEANUP_AFTER_TESTS:-true}"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test function wrapper
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    log_info "Running test: $test_name"
    
    if $test_function; then
        log_success "$test_name"
    else
        log_error "$test_name"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check required tools
    local missing_tools=()
    command -v az >/dev/null 2>&1 || missing_tools+=("azure-cli")
    command -v kubectl >/dev/null 2>&1 || missing_tools+=("kubectl")
    command -v jq >/dev/null 2>&1 || missing_tools+=("jq")
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    # Check Azure authentication
    if ! az account show >/dev/null 2>&1; then
        log_error "Azure CLI not authenticated. Please run 'az login'"
        return 1
    fi
    
    # Check kubectl connectivity
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "kubectl cannot connect to cluster"
        return 1
    fi
    
    # Check Crossplane installation
    if ! kubectl get providers >/dev/null 2>&1; then
        log_error "Crossplane not installed or accessible"
        return 1
    fi
    
    log_success "Prerequisites check passed"
    return 0
}

# Setup test environment
setup_test_environment() {
    log_info "Setting up test environment..."
    
    # Create test namespace
    if ! kubectl get namespace "$TEST_NAMESPACE" >/dev/null 2>&1; then
        kubectl create namespace "$TEST_NAMESPACE"
        log_info "Created test namespace: $TEST_NAMESPACE"
    fi
    
    # Create test data directory if it doesn't exist
    mkdir -p "$TEST_DATA_DIR"
    
    # Create test platform claim
    cat > "$TEST_DATA_DIR/test-platform-claim.yaml" << EOF
apiVersion: astra.platform/v1alpha1
kind: XPlatform
metadata:
  name: integration-test-platform
  namespace: $TEST_NAMESPACE
spec:
  parameters:
    environment: "test"
    location: "$TEST_LOCATION"
    namingPrefix: "astratest"
    containerApp:
      image: "nginx:latest"
      cpu: 0.25
      memory: "0.5Gi"
      minReplicas: 1
      maxReplicas: 3
      environmentVariables:
        - name: "TEST_MODE"
          value: "integration"
      ingress:
        external: true
        targetPort: 80
    security:
      enableKeyVault: true
    storage:
      enableStorage: true
      accountType: "Standard_LRS"
    containerRegistry:
      enableRegistry: true
      sku: "Basic"
EOF
    
    log_success "Test environment setup completed"
    return 0
}

# Test platform deployment
test_platform_deployment() {
    log_info "Testing platform deployment..."
    
    # Apply test platform claim
    if ! kubectl apply -f "$TEST_DATA_DIR/test-platform-claim.yaml"; then
        log_error "Failed to apply test platform claim"
        return 1
    fi
    
    # Wait for platform to be ready
    log_info "Waiting for platform to be ready (timeout: ${TEST_TIMEOUT}s)..."
    if ! timeout "$TEST_TIMEOUT" kubectl wait --for=condition=Ready xplatform integration-test-platform -n "$TEST_NAMESPACE"; then
        log_error "Platform deployment timed out"
        return 1
    fi
    
    log_info "Platform deployment successful"
    return 0
}

# Test Azure resource creation
test_azure_resource_creation() {
    log_info "Testing Azure resource creation..."
    
    # Check if resource group exists
    if ! az group show --name "$TEST_RESOURCE_GROUP" >/dev/null 2>&1; then
        log_error "Resource group $TEST_RESOURCE_GROUP not found"
        return 1
    fi
    
    # Check managed identity
    if ! az identity show --name "astratest-test-identity" --resource-group "$TEST_RESOURCE_GROUP" >/dev/null 2>&1; then
        log_error "Managed identity not found"
        return 1
    fi
    
    # Check Key Vault
    if ! az keyvault show --name "astratest-test-kv" >/dev/null 2>&1; then
        log_error "Key Vault not found"
        return 1
    fi
    
    # Check storage account
    if ! az storage account show --name "astratesttestst" >/dev/null 2>&1; then
        log_error "Storage account not found"
        return 1
    fi
    
    # Check container registry
    if ! az acr show --name "astratesttestacr" >/dev/null 2>&1; then
        log_error "Container registry not found"
        return 1
    fi
    
    # Check container app
    if ! az containerapp show --name "astratest-test-app" --resource-group "$TEST_RESOURCE_GROUP" >/dev/null 2>&1; then
        log_error "Container app not found"
        return 1
    fi
    
    log_info "All Azure resources created successfully"
    return 0
}

# Test resource configuration
test_resource_configuration() {
    log_info "Testing resource configuration..."
    
    # Test container app configuration
    local app_config
    app_config=$(az containerapp show --name "astratest-test-app" --resource-group "$TEST_RESOURCE_GROUP" 2>/dev/null)
    
    if [[ -z "$app_config" ]]; then
        log_error "Failed to get container app configuration"
        return 1
    fi
    
    # Check CPU allocation
    local cpu_allocation
    cpu_allocation=$(echo "$app_config" | jq -r '.properties.template.containers[0].resources.cpu // empty')
    if [[ "$cpu_allocation" != "0.25" ]]; then
        log_error "Incorrect CPU allocation: expected 0.25, got $cpu_allocation"
        return 1
    fi
    
    # Check memory allocation
    local memory_allocation
    memory_allocation=$(echo "$app_config" | jq -r '.properties.template.containers[0].resources.memory // empty')
    if [[ "$memory_allocation" != "0.5Gi" ]]; then
        log_error "Incorrect memory allocation: expected 0.5Gi, got $memory_allocation"
        return 1
    fi
    
    # Check scaling configuration
    local min_replicas
    min_replicas=$(echo "$app_config" | jq -r '.properties.template.scale.minReplicas // empty')
    if [[ "$min_replicas" != "1" ]]; then
        log_error "Incorrect min replicas: expected 1, got $min_replicas"
        return 1
    fi
    
    local max_replicas
    max_replicas=$(echo "$app_config" | jq -r '.properties.template.scale.maxReplicas // empty')
    if [[ "$max_replicas" != "3" ]]; then
        log_error "Incorrect max replicas: expected 3, got $max_replicas"
        return 1
    fi
    
    log_info "Resource configuration validation passed"
    return 0
}

# Test application connectivity
test_application_connectivity() {
    log_info "Testing application connectivity..."
    
    # Get application URL
    local app_url
    app_url=$(az containerapp show --name "astratest-test-app" --resource-group "$TEST_RESOURCE_GROUP" --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null)
    
    if [[ -z "$app_url" ]]; then
        log_error "Failed to get application URL"
        return 1
    fi
    
    # Test HTTP connectivity
    local max_attempts=10
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Testing connectivity to https://$app_url (attempt $attempt/$max_attempts)..."
        
        if curl -f -s "https://$app_url" >/dev/null 2>&1; then
            log_info "Application is accessible"
            return 0
        fi
        
        sleep 30
        attempt=$((attempt + 1))
    done
    
    log_error "Application not accessible after $max_attempts attempts"
    return 1
}

# Test managed identity integration
test_managed_identity_integration() {
    log_info "Testing managed identity integration..."
    
    # Get managed identity details
    local identity_details
    identity_details=$(az identity show --name "astratest-test-identity" --resource-group "$TEST_RESOURCE_GROUP" 2>/dev/null)
    
    if [[ -z "$identity_details" ]]; then
        log_error "Failed to get managed identity details"
        return 1
    fi
    
    # Check if identity has proper client ID
    local client_id
    client_id=$(echo "$identity_details" | jq -r '.clientId // empty')
    if [[ -z "$client_id" ]]; then
        log_error "Managed identity missing client ID"
        return 1
    fi
    
    # Check if container app is using the managed identity
    local app_identity
    app_identity=$(az containerapp show --name "astratest-test-app" --resource-group "$TEST_RESOURCE_GROUP" --query "identity.userAssignedIdentities" -o json 2>/dev/null)
    
    if [[ "$app_identity" == "null" ]] || [[ -z "$app_identity" ]]; then
        log_error "Container app not configured with managed identity"
        return 1
    fi
    
    log_info "Managed identity integration validation passed"
    return 0
}

# Test Key Vault integration
test_keyvault_integration() {
    log_info "Testing Key Vault integration..."
    
    # Test Key Vault accessibility
    if ! az keyvault secret list --vault-name "astratest-test-kv" >/dev/null 2>&1; then
        log_error "Cannot access Key Vault secrets"
        return 1
    fi
    
    # Create a test secret
    local test_secret_name="integration-test-secret"
    local test_secret_value="test-value-$(date +%s)"
    
    if ! az keyvault secret set --vault-name "astratest-test-kv" --name "$test_secret_name" --value "$test_secret_value" >/dev/null 2>&1; then
        log_error "Cannot create test secret in Key Vault"
        return 1
    fi
    
    # Verify secret was created
    local retrieved_value
    retrieved_value=$(az keyvault secret show --vault-name "astratest-test-kv" --name "$test_secret_name" --query "value" -o tsv 2>/dev/null)
    
    if [[ "$retrieved_value" != "$test_secret_value" ]]; then
        log_error "Test secret value mismatch"
        return 1
    fi
    
    # Clean up test secret
    az keyvault secret delete --vault-name "astratest-test-kv" --name "$test_secret_name" >/dev/null 2>&1 || true
    
    log_info "Key Vault integration validation passed"
    return 0
}

# Test storage integration
test_storage_integration() {
    log_info "Testing storage integration..."
    
    # Check storage account accessibility
    if ! az storage account show --name "astratesttestst" >/dev/null 2>&1; then
        log_error "Storage account not accessible"
        return 1
    fi
    
    # Get storage account key
    local storage_key
    storage_key=$(az storage account keys list --account-name "astratesttestst" --query "[0].value" -o tsv 2>/dev/null)
    
    if [[ -z "$storage_key" ]]; then
        log_error "Cannot retrieve storage account key"
        return 1
    fi
    
    # Test blob storage
    local container_name="integration-test"
    if ! az storage container create --name "$container_name" --account-name "astratesttestst" --account-key "$storage_key" >/dev/null 2>&1; then
        log_error "Cannot create storage container"
        return 1
    fi
    
    # Clean up test container
    az storage container delete --name "$container_name" --account-name "astratesttestst" --account-key "$storage_key" >/dev/null 2>&1 || true
    
    log_info "Storage integration validation passed"
    return 0
}

# Test container registry integration
test_container_registry_integration() {
    log_info "Testing container registry integration..."
    
    # Check ACR accessibility
    if ! az acr show --name "astratesttestacr" >/dev/null 2>&1; then
        log_error "Container registry not accessible"
        return 1
    fi
    
    # Test login to ACR
    if ! az acr login --name "astratesttestacr" >/dev/null 2>&1; then
        log_error "Cannot login to container registry"
        return 1
    fi
    
    # Check repository access
    az acr repository list --name "astratesttestacr" >/dev/null 2>&1 || true
    
    log_info "Container registry integration validation passed"
    return 0
}

# Cleanup test resources
cleanup_test_resources() {
    if [[ "$CLEANUP_AFTER_TESTS" == "true" ]]; then
        log_info "Cleaning up test resources..."
        
        # Delete platform claim
        kubectl delete xplatform integration-test-platform -n "$TEST_NAMESPACE" --wait=false 2>/dev/null || true
        
        # Wait for Azure resources to be deleted
        log_info "Waiting for Azure resources to be deleted..."
        sleep 60
        
        # Force delete resource group if it still exists
        if az group exists --name "$TEST_RESOURCE_GROUP" 2>/dev/null; then
            log_info "Force deleting resource group..."
            az group delete --name "$TEST_RESOURCE_GROUP" --yes --no-wait 2>/dev/null || true
        fi
        
        # Delete test namespace
        kubectl delete namespace "$TEST_NAMESPACE" --wait=false 2>/dev/null || true
        
        log_success "Cleanup initiated"
    else
        log_info "Skipping cleanup (CLEANUP_AFTER_TESTS=false)"
    fi
}

# Main test execution
main() {
    log_info "Starting Azure resource integration tests..."
    log_info "Test configuration:"
    echo "  Namespace: $TEST_NAMESPACE"
    echo "  Resource Group: $TEST_RESOURCE_GROUP"
    echo "  Location: $TEST_LOCATION"
    echo "  Timeout: ${TEST_TIMEOUT}s"
    echo "  Cleanup: $CLEANUP_AFTER_TESTS"
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    # Setup test environment
    if ! setup_test_environment; then
        exit 1
    fi
    
    # Run tests
    run_test "Platform Deployment" test_platform_deployment
    run_test "Azure Resource Creation" test_azure_resource_creation
    run_test "Resource Configuration" test_resource_configuration
    run_test "Application Connectivity" test_application_connectivity
    run_test "Managed Identity Integration" test_managed_identity_integration
    run_test "Key Vault Integration" test_keyvault_integration
    run_test "Storage Integration" test_storage_integration
    run_test "Container Registry Integration" test_container_registry_integration
    
    # Cleanup
    cleanup_test_resources
    
    # Print summary
    echo
    log_info "Test Summary:"
    echo "  Tests Run: $TESTS_RUN"
    echo "  Tests Passed: $TESTS_PASSED"
    echo "  Tests Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All Azure resource integration tests passed!"
        exit 0
    else
        log_error "Some Azure resource integration tests failed!"
        exit 1
    fi
}

# Trap to ensure cleanup on script exit
trap cleanup_test_resources EXIT

# Run main function
main "$@"