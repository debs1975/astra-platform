#!/bin/bash
set -euo pipefail

# End-to-End Environment Test Runner
# Complete environment deployment and validation testing

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
E2E_TEST_PREFIX="${E2E_TEST_PREFIX:-e2etest}"
E2E_TEST_LOCATION="${E2E_TEST_LOCATION:-Central India}"
E2E_TEST_TIMEOUT="${E2E_TEST_TIMEOUT:-3600}"
PRESERVE_ON_FAILURE="${PRESERVE_ON_FAILURE:-false}"

# Test environments
TEST_ENVIRONMENTS=("dev" "staging")
CURRENT_TEST_ENV=""

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
        if [[ "$PRESERVE_ON_FAILURE" == "true" ]]; then
            log_warning "Preserving resources for debugging (PRESERVE_ON_FAILURE=true)"
            return 1
        fi
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking E2E test prerequisites..."
    
    # Check required tools
    local missing_tools=()
    command -v az >/dev/null 2>&1 || missing_tools+=("azure-cli")
    command -v kubectl >/dev/null 2>&1 || missing_tools+=("kubectl")
    command -v jq >/dev/null 2>&1 || missing_tools+=("jq")
    command -v docker >/dev/null 2>&1 || missing_tools+=("docker")
    
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
    
    # Verify Azure provider is healthy
    if ! kubectl get providers provider-azure -o jsonpath='{.status.conditions[?(@.type=="Healthy")].status}' | grep -q "True"; then
        log_error "Azure provider not healthy"
        return 1
    fi
    
    log_success "Prerequisites check passed"
    return 0
}

# Setup test environment
setup_test_environment() {
    log_info "Setting up E2E test environment..."
    
    # Create test data directory
    mkdir -p "$TEST_DATA_DIR"
    
    # Generate test configurations for each environment
    for env in "${TEST_ENVIRONMENTS[@]}"; do
        local namespace="e2e-test-$env"
        local platform_name="$E2E_TEST_PREFIX-$env-platform"
        
        # Create namespace
        kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
        
        # Generate platform configuration
        cat > "$TEST_DATA_DIR/$env-platform-config.yaml" << EOF
apiVersion: astra.platform/v1alpha1
kind: XPlatform
metadata:
  name: $platform_name
  namespace: $namespace
spec:
  parameters:
    environment: "$env"
    location: "$E2E_TEST_LOCATION"
    namingPrefix: "$E2E_TEST_PREFIX"
    containerApp:
      image: "nginx:latest"
      cpu: $([ "$env" = "prod" ] && echo "0.5" || echo "0.25")
      memory: $([ "$env" = "prod" ] && echo "1Gi" || echo "0.5Gi")
      minReplicas: $([ "$env" = "prod" ] && echo "2" || echo "1")
      maxReplicas: $([ "$env" = "prod" ] && echo "10" || echo "5")
      environmentVariables:
        - name: "ENVIRONMENT"
          value: "$env"
        - name: "TEST_MODE"
          value: "e2e"
        - name: "NGINX_HOST"
          value: "0.0.0.0"
        - name: "NGINX_PORT"
          value: "80"
      ingress:
        external: true
        targetPort: 80
        allowInsecure: false
    security:
      enableKeyVault: true
    storage:
      enableStorage: true
      accountType: $([ "$env" = "prod" ] && echo "Standard_GRS" || echo "Standard_LRS")
    containerRegistry:
      enableRegistry: true
      sku: $([ "$env" = "prod" ] && echo "Standard" || echo "Basic")
    tags:
      Environment: "$env"
      TestType: "e2e"
      TestRun: "$(date +%Y%m%d-%H%M%S)"
EOF
    done
    
    log_success "Test environment setup completed"
    return 0
}

# Deploy environment
deploy_environment() {
    local env="$1"
    CURRENT_TEST_ENV="$env"
    
    log_info "Deploying $env environment..."
    
    local namespace="e2e-test-$env"
    local platform_name="$E2E_TEST_PREFIX-$env-platform"
    local config_file="$TEST_DATA_DIR/$env-platform-config.yaml"
    
    # Apply platform configuration
    if ! kubectl apply -f "$config_file"; then
        log_error "Failed to apply platform configuration for $env"
        return 1
    fi
    
    # Wait for platform to be ready with extended timeout for E2E
    log_info "Waiting for $env platform to be ready (timeout: ${E2E_TEST_TIMEOUT}s)..."
    if ! timeout "$E2E_TEST_TIMEOUT" kubectl wait --for=condition=Ready xplatform "$platform_name" -n "$namespace"; then
        log_error "$env platform deployment timed out"
        
        # Show status for debugging
        kubectl describe xplatform "$platform_name" -n "$namespace" || true
        kubectl get managed | grep "$E2E_TEST_PREFIX-$env" || true
        
        return 1
    fi
    
    log_success "$env environment deployed successfully"
    return 0
}

# Validate environment deployment
validate_environment_deployment() {
    local env="$1"
    
    log_info "Validating $env environment deployment..."
    
    local resource_group="$E2E_TEST_PREFIX-$env-rg"
    local namespace="e2e-test-$env"
    local platform_name="$E2E_TEST_PREFIX-$env-platform"
    
    # Check Azure resource group
    if ! az group show --name "$resource_group" >/dev/null 2>&1; then
        log_error "$env: Resource group $resource_group not found"
        return 1
    fi
    
    # Check all expected Azure resources
    local expected_resources=(
        "$E2E_TEST_PREFIX-$env-identity"  # Managed Identity
        "$E2E_TEST_PREFIX-$env-kv"        # Key Vault
        "${E2E_TEST_PREFIX}${env}st"      # Storage Account
        "${E2E_TEST_PREFIX}${env}acr"     # Container Registry
        "$E2E_TEST_PREFIX-$env-app"       # Container App
    )
    
    for resource in "${expected_resources[@]}"; do
        # Different commands for different resource types
        case $resource in
            *-identity)
                if ! az identity show --name "$resource" --resource-group "$resource_group" >/dev/null 2>&1; then
                    log_error "$env: Managed Identity $resource not found"
                    return 1
                fi
                ;;
            *-kv)
                if ! az keyvault show --name "$resource" >/dev/null 2>&1; then
                    log_error "$env: Key Vault $resource not found"
                    return 1
                fi
                ;;
            *st)
                if ! az storage account show --name "$resource" >/dev/null 2>&1; then
                    log_error "$env: Storage Account $resource not found"
                    return 1
                fi
                ;;
            *acr)
                if ! az acr show --name "$resource" >/dev/null 2>&1; then
                    log_error "$env: Container Registry $resource not found"
                    return 1
                fi
                ;;
            *-app)
                if ! az containerapp show --name "$resource" --resource-group "$resource_group" >/dev/null 2>&1; then
                    log_error "$env: Container App $resource not found"
                    return 1
                fi
                ;;
        esac
    done
    
    # Validate platform status in Kubernetes
    local platform_status
    platform_status=$(kubectl get xplatform "$platform_name" -n "$namespace" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    
    if [[ "$platform_status" != "True" ]]; then
        log_error "$env: Platform not in Ready state"
        return 1
    fi
    
    log_success "$env environment validation passed"
    return 0
}

# Test application functionality
test_application_functionality() {
    local env="$1"
    
    log_info "Testing $env application functionality..."
    
    local namespace="e2e-test-$env"
    local platform_name="$E2E_TEST_PREFIX-$env-platform"
    
    # Get application URL from platform status
    local app_url
    app_url=$(kubectl get xplatform "$platform_name" -n "$namespace" -o jsonpath='{.status.components.containerApp.applicationUrl}' 2>/dev/null)
    
    if [[ -z "$app_url" ]]; then
        log_error "$env: Could not retrieve application URL"
        return 1
    fi
    
    log_info "$env: Testing application at https://$app_url"
    
    # Test application accessibility with retries
    local max_attempts=20
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "$env: Testing connectivity (attempt $attempt/$max_attempts)..."
        
        if curl -f -s --max-time 30 "https://$app_url" >/dev/null 2>&1; then
            log_info "$env: Application is accessible"
            break
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            log_error "$env: Application not accessible after $max_attempts attempts"
            return 1
        fi
        
        sleep 15
        attempt=$((attempt + 1))
    done
    
    # Test application response
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "https://$app_url" 2>/dev/null || echo "000")
    
    if [[ "$response_code" != "200" ]]; then
        log_error "$env: Application returned HTTP $response_code instead of 200"
        return 1
    fi
    
    # Test application content
    local content
    content=$(curl -s "https://$app_url" 2>/dev/null || echo "")
    
    if [[ ! "$content" =~ "nginx" ]]; then
        log_error "$env: Application content does not appear to be nginx default page"
        return 1
    fi
    
    log_success "$env application functionality test passed"
    return 0
}

# Test environment-specific configuration
test_environment_configuration() {
    local env="$1"
    
    log_info "Testing $env environment-specific configuration..."
    
    local resource_group="$E2E_TEST_PREFIX-$env-rg"
    local app_name="$E2E_TEST_PREFIX-$env-app"
    
    # Get container app configuration
    local app_config
    app_config=$(az containerapp show --name "$app_name" --resource-group "$resource_group" 2>/dev/null)
    
    if [[ -z "$app_config" ]]; then
        log_error "$env: Failed to get container app configuration"
        return 1
    fi
    
    # Validate environment-specific settings
    case "$env" in
        "dev")
            # Dev should have minimal resources
            local expected_cpu="0.25"
            local expected_memory="0.5Gi"
            local expected_min_replicas="1"
            ;;
        "staging")
            # Staging should have moderate resources
            local expected_cpu="0.25"
            local expected_memory="0.5Gi"
            local expected_min_replicas="1"
            ;;
        "prod")
            # Prod should have higher resources
            local expected_cpu="0.5"
            local expected_memory="1Gi"
            local expected_min_replicas="2"
            ;;
    esac
    
    # Validate CPU allocation
    local actual_cpu
    actual_cpu=$(echo "$app_config" | jq -r '.properties.template.containers[0].resources.cpu // empty')
    if [[ "$actual_cpu" != "$expected_cpu" ]]; then
        log_error "$env: Incorrect CPU allocation: expected $expected_cpu, got $actual_cpu"
        return 1
    fi
    
    # Validate memory allocation
    local actual_memory
    actual_memory=$(echo "$app_config" | jq -r '.properties.template.containers[0].resources.memory // empty')
    if [[ "$actual_memory" != "$expected_memory" ]]; then
        log_error "$env: Incorrect memory allocation: expected $expected_memory, got $actual_memory"
        return 1
    fi
    
    # Validate replica configuration
    local actual_min_replicas
    actual_min_replicas=$(echo "$app_config" | jq -r '.properties.template.scale.minReplicas // empty')
    if [[ "$actual_min_replicas" != "$expected_min_replicas" ]]; then
        log_error "$env: Incorrect min replicas: expected $expected_min_replicas, got $actual_min_replicas"
        return 1
    fi
    
    # Validate environment variables
    local env_vars
    env_vars=$(echo "$app_config" | jq -r '.properties.template.containers[0].env[]? | select(.name=="ENVIRONMENT") | .value')
    if [[ "$env_vars" != "$env" ]]; then
        log_error "$env: Incorrect ENVIRONMENT variable: expected $env, got $env_vars"
        return 1
    fi
    
    log_success "$env environment configuration test passed"
    return 0
}

# Test scaling functionality
test_scaling_functionality() {
    local env="$1"
    
    log_info "Testing $env scaling functionality..."
    
    local namespace="e2e-test-$env"
    local platform_name="$E2E_TEST_PREFIX-$env-platform"
    local resource_group="$E2E_TEST_PREFIX-$env-rg"
    local app_name="$E2E_TEST_PREFIX-$env-app"
    
    # Get application URL
    local app_url
    app_url=$(kubectl get xplatform "$platform_name" -n "$namespace" -o jsonpath='{.status.components.containerApp.applicationUrl}' 2>/dev/null)
    
    if [[ -z "$app_url" ]]; then
        log_error "$env: Could not retrieve application URL for scaling test"
        return 1
    fi
    
    # Generate load to trigger scaling
    log_info "$env: Generating load to trigger auto-scaling..."
    
    # Start background load generation
    local load_pids=()
    for i in {1..10}; do
        (
            for j in {1..20}; do
                curl -s "https://$app_url" >/dev/null 2>&1 || true
                sleep 0.5
            done
        ) &
        load_pids+=($!)
    done
    
    # Wait for scaling to potentially occur
    sleep 120
    
    # Stop load generation
    for pid in "${load_pids[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    wait
    
    # Check if app scaled (this is observational, not strictly required to pass)
    local replica_count
    replica_count=$(az containerapp revision list --name "$app_name" --resource-group "$resource_group" --query "length([?properties.active])" -o tsv 2>/dev/null || echo "1")
    
    log_info "$env: Application has $replica_count active revision(s) after load test"
    
    # The test passes as long as the application remained responsive
    if curl -f -s --max-time 10 "https://$app_url" >/dev/null 2>&1; then
        log_success "$env scaling functionality test passed (app remained responsive under load)"
        return 0
    else
        log_error "$env: Application became unresponsive during scaling test"
        return 1
    fi
}

# Cleanup environment
cleanup_environment() {
    local env="$1"
    
    if [[ "$PRESERVE_ON_FAILURE" == "true" ]] && [[ $TESTS_FAILED -gt 0 ]]; then
        log_warning "Preserving $env environment for debugging"
        return 0
    fi
    
    log_info "Cleaning up $env environment..."
    
    local namespace="e2e-test-$env"
    local platform_name="$E2E_TEST_PREFIX-$env-platform"
    local resource_group="$E2E_TEST_PREFIX-$env-rg"
    
    # Delete platform (this should trigger Azure resource cleanup)
    kubectl delete xplatform "$platform_name" -n "$namespace" --wait=false 2>/dev/null || true
    
    # Wait a bit for cleanup to start
    sleep 30
    
    # Force delete resource group if it still exists after a reasonable wait
    local cleanup_wait=300  # 5 minutes
    local waited=0
    
    while [[ $waited -lt $cleanup_wait ]]; do
        if ! az group exists --name "$resource_group" 2>/dev/null; then
            break
        fi
        sleep 10
        waited=$((waited + 10))
    done
    
    # Force delete if still exists
    if az group exists --name "$resource_group" 2>/dev/null; then
        log_warning "$env: Force deleting resource group $resource_group"
        az group delete --name "$resource_group" --yes --no-wait 2>/dev/null || true
    fi
    
    # Delete namespace
    kubectl delete namespace "$namespace" --wait=false 2>/dev/null || true
    
    log_success "$env environment cleanup initiated"
    return 0
}

# Test individual environment
test_environment() {
    local env="$1"
    
    log_info "Starting E2E test for $env environment"
    
    # Deploy environment
    if ! deploy_environment "$env"; then
        cleanup_environment "$env"
        return 1
    fi
    
    # Run validation tests
    run_test "$env Environment Deployment Validation" "validate_environment_deployment $env"
    run_test "$env Application Functionality Test" "test_application_functionality $env"
    run_test "$env Environment Configuration Test" "test_environment_configuration $env"
    run_test "$env Scaling Functionality Test" "test_scaling_functionality $env"
    
    # Cleanup
    cleanup_environment "$env"
    
    return 0
}

# Main test execution
main() {
    log_info "Starting E2E Environment Tests..."
    log_info "Test configuration:"
    echo "  Test Prefix: $E2E_TEST_PREFIX"
    echo "  Location: $E2E_TEST_LOCATION"
    echo "  Timeout: ${E2E_TEST_TIMEOUT}s"
    echo "  Preserve on Failure: $PRESERVE_ON_FAILURE"
    echo "  Test Environments: ${TEST_ENVIRONMENTS[*]}"
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    # Setup test environment
    if ! setup_test_environment; then
        exit 1
    fi
    
    # Test each environment
    for env in "${TEST_ENVIRONMENTS[@]}"; do
        log_info "Testing environment: $env"
        test_environment "$env"
    done
    
    # Print summary
    echo
    log_info "E2E Test Summary:"
    echo "  Tests Run: $TESTS_RUN"
    echo "  Tests Passed: $TESTS_PASSED"
    echo "  Tests Failed: $TESTS_FAILED"
    echo "  Environments Tested: ${TEST_ENVIRONMENTS[*]}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All E2E environment tests passed!"
        exit 0
    else
        log_error "Some E2E environment tests failed!"
        exit 1
    fi
}

# Cleanup function for script exit
cleanup_on_exit() {
    if [[ -n "${CURRENT_TEST_ENV:-}" ]] && [[ "$PRESERVE_ON_FAILURE" != "true" ]]; then
        cleanup_environment "$CURRENT_TEST_ENV"
    fi
}

# Trap to ensure cleanup on script exit
trap cleanup_on_exit EXIT

# Run main function
main "$@"