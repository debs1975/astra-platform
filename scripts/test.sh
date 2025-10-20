#!/bin/bash
set -euo pipefail

# Test execution script for Astra Platform
# Usage: ./test.sh [unit|integration|e2e] [test-category] [options]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_DIR="$PROJECT_ROOT/tests"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
TEST_TYPE=""
TEST_CATEGORY=""
VERBOSE=false
CLEANUP=${CLEANUP_AFTER_TESTS:-true}
PARALLEL=${PARALLEL_TESTS:-false}
TIMEOUT=${TEST_TIMEOUT:-600}

# Help function
show_help() {
    cat << EOF
Usage: $0 [TEST_TYPE] [TEST_CATEGORY] [OPTIONS]

Test Types:
    unit            Run unit tests
    integration     Run integration tests  
    e2e             Run end-to-end tests
    all             Run all tests

Test Categories:
    Unit Test Categories:
        xrd-validation      XRD schema validation tests
        composition-tests   Composition logic tests
        script-tests        Shell script tests
        
    Integration Test Categories:
        azure-resources     Azure resource tests
        crossplane-tests    Crossplane provider tests
        security-tests      Security and compliance tests
        
    E2E Test Categories:
        environment-tests   Environment deployment tests
        application-tests   Application deployment tests
        performance-tests   Load and performance tests

Options:
    --verbose, -v       Enable verbose output
    --no-cleanup        Don't cleanup resources after tests
    --parallel, -p      Run tests in parallel
    --timeout=SECONDS   Set test timeout (default: 600)
    --help, -h          Show this help message

Environment Variables:
    AZURE_SUBSCRIPTION_ID   Azure subscription ID
    AZURE_TENANT_ID         Azure tenant ID
    AZURE_CLIENT_ID         Service principal client ID
    AZURE_CLIENT_SECRET     Service principal secret
    TEST_ENVIRONMENT        Test environment name (default: test)
    TEST_RESOURCE_GROUP     Test resource group (default: astra-test-rg)
    TEST_LOCATION          Test location (default: Central India)

Examples:
    $0 unit                           # Run all unit tests
    $0 unit xrd-validation           # Run XRD validation tests
    $0 integration --verbose         # Run integration tests with verbose output
    $0 e2e environment-tests         # Run environment deployment tests
    $0 all --parallel               # Run all tests in parallel
EOF
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            unit|integration|e2e|all)
                TEST_TYPE="$1"
                shift
                ;;
            xrd-validation|composition-tests|script-tests|azure-resources|crossplane-tests|security-tests|environment-tests|application-tests|performance-tests)
                TEST_CATEGORY="$1"
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --no-cleanup)
                CLEANUP=false
                shift
                ;;
            --parallel|-p)
                PARALLEL=true
                shift
                ;;
            --timeout=*)
                TIMEOUT="${1#*=}"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check required tools
    local missing_tools=()
    
    command -v kubectl >/dev/null 2>&1 || missing_tools+=("kubectl")
    command -v az >/dev/null 2>&1 || missing_tools+=("azure-cli")
    command -v yq >/dev/null 2>&1 || missing_tools+=("yq")
    command -v jq >/dev/null 2>&1 || missing_tools+=("jq")
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install missing tools and try again"
        exit 1
    fi
    
    # Check Azure authentication for integration and e2e tests
    if [[ "$TEST_TYPE" == "integration" || "$TEST_TYPE" == "e2e" || "$TEST_TYPE" == "all" ]]; then
        if ! az account show >/dev/null 2>&1; then
            log_error "Azure CLI not authenticated. Please run 'az login'"
            exit 1
        fi
        
        # Verify required environment variables
        local missing_vars=()
        [[ -z "${AZURE_SUBSCRIPTION_ID:-}" ]] && missing_vars+=("AZURE_SUBSCRIPTION_ID")
        [[ -z "${AZURE_TENANT_ID:-}" ]] && missing_vars+=("AZURE_TENANT_ID")
        
        if [ ${#missing_vars[@]} -ne 0 ]; then
            log_warning "Missing environment variables: ${missing_vars[*]}"
            log_info "Using Azure CLI default subscription and tenant"
        fi
    fi
    
    log_success "Prerequisites check passed"
}

# Setup test environment
setup_test_environment() {
    log_info "Setting up test environment..."
    
    # Set default values
    export TEST_ENVIRONMENT="${TEST_ENVIRONMENT:-test}"
    export TEST_RESOURCE_GROUP="${TEST_RESOURCE_GROUP:-astra-test-rg}"
    export TEST_LOCATION="${TEST_LOCATION:-Central India}"
    export TEST_TIMEOUT="$TIMEOUT"
    
    # Create test directories
    mkdir -p "$TEST_DIR/reports"
    mkdir -p "$TEST_DIR/logs"
    
    # Create test report file
    export TEST_REPORT_FILE="$TEST_DIR/reports/test-results-$(date +%Y%m%d-%H%M%S).json"
    echo '{"tests": [], "summary": {}}' > "$TEST_REPORT_FILE"
    
    log_success "Test environment setup complete"
}

# Run unit tests
run_unit_tests() {
    local category="$1"
    log_info "Running unit tests${category:+ for $category}..."
    
    local test_dirs=()
    if [[ -n "$category" ]]; then
        test_dirs=("$TEST_DIR/unit/$category")
    else
        test_dirs=($(find "$TEST_DIR/unit" -mindepth 1 -maxdepth 1 -type d))
    fi
    
    local failed_tests=0
    local total_tests=0
    
    for test_dir in "${test_dirs[@]}"; do
        if [[ -d "$test_dir" && -f "$test_dir/run-tests.sh" ]]; then
            local test_name=$(basename "$test_dir")
            log_info "Running $test_name unit tests..."
            
            if $VERBOSE; then
                bash "$test_dir/run-tests.sh" 2>&1 | tee "$TEST_DIR/logs/${test_name}-unit.log"
                local exit_code=${PIPESTATUS[0]}
            else
                bash "$test_dir/run-tests.sh" > "$TEST_DIR/logs/${test_name}-unit.log" 2>&1
                local exit_code=$?
            fi
            
            total_tests=$((total_tests + 1))
            if [[ $exit_code -eq 0 ]]; then
                log_success "$test_name unit tests passed"
            else
                log_error "$test_name unit tests failed"
                failed_tests=$((failed_tests + 1))
            fi
        fi
    done
    
    if [[ $failed_tests -eq 0 ]]; then
        log_success "All unit tests passed ($total_tests/$total_tests)"
        return 0
    else
        log_error "Unit tests failed ($failed_tests/$total_tests failed)"
        return 1
    fi
}

# Run integration tests
run_integration_tests() {
    local category="$1"
    log_info "Running integration tests${category:+ for $category}..."
    
    local test_dirs=()
    if [[ -n "$category" ]]; then
        test_dirs=("$TEST_DIR/integration/$category")
    else
        test_dirs=($(find "$TEST_DIR/integration" -mindepth 1 -maxdepth 1 -type d))
    fi
    
    local failed_tests=0
    local total_tests=0
    
    for test_dir in "${test_dirs[@]}"; do
        if [[ -d "$test_dir" && -f "$test_dir/run-tests.sh" ]]; then
            local test_name=$(basename "$test_dir")
            log_info "Running $test_name integration tests..."
            
            # Set timeout for integration tests
            timeout $TIMEOUT bash "$test_dir/run-tests.sh" > "$TEST_DIR/logs/${test_name}-integration.log" 2>&1
            local exit_code=$?
            
            if $VERBOSE && [[ $exit_code -ne 0 ]]; then
                cat "$TEST_DIR/logs/${test_name}-integration.log"
            fi
            
            total_tests=$((total_tests + 1))
            if [[ $exit_code -eq 0 ]]; then
                log_success "$test_name integration tests passed"
            else
                if [[ $exit_code -eq 124 ]]; then
                    log_error "$test_name integration tests timed out after ${TIMEOUT}s"
                else
                    log_error "$test_name integration tests failed"
                fi
                failed_tests=$((failed_tests + 1))
            fi
        fi
    done
    
    if [[ $failed_tests -eq 0 ]]; then
        log_success "All integration tests passed ($total_tests/$total_tests)"
        return 0
    else
        log_error "Integration tests failed ($failed_tests/$total_tests failed)"
        return 1
    fi
}

# Run e2e tests
run_e2e_tests() {
    local category="$1"
    log_info "Running end-to-end tests${category:+ for $category}..."
    
    local test_dirs=()
    if [[ -n "$category" ]]; then
        test_dirs=("$TEST_DIR/e2e/$category")
    else
        test_dirs=($(find "$TEST_DIR/e2e" -mindepth 1 -maxdepth 1 -type d))
    fi
    
    local failed_tests=0
    local total_tests=0
    
    for test_dir in "${test_dirs[@]}"; do
        if [[ -d "$test_dir" && -f "$test_dir/run-tests.sh" ]]; then
            local test_name=$(basename "$test_dir")
            log_info "Running $test_name e2e tests..."
            
            # E2E tests get longer timeout
            timeout $((TIMEOUT * 2)) bash "$test_dir/run-tests.sh" > "$TEST_DIR/logs/${test_name}-e2e.log" 2>&1
            local exit_code=$?
            
            if $VERBOSE && [[ $exit_code -ne 0 ]]; then
                cat "$TEST_DIR/logs/${test_name}-e2e.log"
            fi
            
            total_tests=$((total_tests + 1))
            if [[ $exit_code -eq 0 ]]; then
                log_success "$test_name e2e tests passed"
            else
                if [[ $exit_code -eq 124 ]]; then
                    log_error "$test_name e2e tests timed out after $((TIMEOUT * 2))s"
                else
                    log_error "$test_name e2e tests failed"
                fi
                failed_tests=$((failed_tests + 1))
            fi
        fi
    done
    
    if [[ $failed_tests -eq 0 ]]; then
        log_success "All e2e tests passed ($total_tests/$total_tests)"
        return 0
    else
        log_error "E2E tests failed ($failed_tests/$total_tests failed)"
        return 1
    fi
}

# Cleanup resources
cleanup_resources() {
    if [[ "$CLEANUP" == "true" ]]; then
        log_info "Cleaning up test resources..."
        
        # Run cleanup script if it exists
        if [[ -f "$PROJECT_ROOT/scripts/cleanup-tests.sh" ]]; then
            bash "$PROJECT_ROOT/scripts/cleanup-tests.sh" || log_warning "Cleanup script failed"
        fi
        
        # Clean up test resource group
        if az group exists --name "$TEST_RESOURCE_GROUP" 2>/dev/null; then
            log_info "Deleting test resource group: $TEST_RESOURCE_GROUP"
            az group delete --name "$TEST_RESOURCE_GROUP" --yes --no-wait || log_warning "Failed to delete test resource group"
        fi
        
        log_success "Cleanup completed"
    else
        log_info "Skipping cleanup (CLEANUP_AFTER_TESTS=false)"
    fi
}

# Generate test report
generate_report() {
    log_info "Generating test report..."
    
    local report_file="$TEST_DIR/reports/test-summary-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$report_file" << EOF
Astra Platform Test Results
==========================
Date: $(date)
Test Type: $TEST_TYPE
Test Category: ${TEST_CATEGORY:-all}
Environment: $TEST_ENVIRONMENT

Test Configuration:
- Timeout: ${TIMEOUT}s
- Cleanup: $CLEANUP
- Parallel: $PARALLEL
- Verbose: $VERBOSE

Logs Location: $TEST_DIR/logs/
Reports Location: $TEST_DIR/reports/

Test execution completed.
EOF
    
    log_success "Test report generated: $report_file"
}

# Main execution
main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Show help if no test type specified
    if [[ -z "$TEST_TYPE" ]]; then
        log_error "No test type specified"
        show_help
        exit 1
    fi
    
    # Setup
    check_prerequisites
    setup_test_environment
    
    local exit_code=0
    
    # Run tests based on type
    case "$TEST_TYPE" in
        unit)
            run_unit_tests "$TEST_CATEGORY" || exit_code=1
            ;;
        integration)
            run_integration_tests "$TEST_CATEGORY" || exit_code=1
            ;;
        e2e)
            run_e2e_tests "$TEST_CATEGORY" || exit_code=1
            ;;
        all)
            log_info "Running complete test suite..."
            run_unit_tests "" || exit_code=1
            run_integration_tests "" || exit_code=1
            run_e2e_tests "" || exit_code=1
            ;;
        *)
            log_error "Invalid test type: $TEST_TYPE"
            exit 1
            ;;
    esac
    
    # Cleanup and reporting
    cleanup_resources
    generate_report
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "All tests completed successfully!"
    else
        log_error "Some tests failed. Check logs for details."
    fi
    
    exit $exit_code
}

# Run main function with all arguments
main "$@"