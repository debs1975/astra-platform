#!/bin/bash
set -euo pipefail

# XRD Validation Test Runner
# Tests all XRD definitions for syntax, schema, and parameter validation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PACKAGES_DIR="$PROJECT_ROOT/packages"
TEST_DATA_DIR="$SCRIPT_DIR/test-data"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Test function
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

# Test XRD YAML syntax
test_xrd_yaml_syntax() {
    local failed_files=()
    
    for xrd_file in "$PACKAGES_DIR"/*/definition.yaml; do
        if [[ -f "$xrd_file" ]]; then
            if ! yq eval '.' "$xrd_file" >/dev/null 2>&1; then
                failed_files+=("$xrd_file")
            fi
        fi
    done
    
    if [[ ${#failed_files[@]} -eq 0 ]]; then
        return 0
    else
        log_error "YAML syntax errors in: ${failed_files[*]}"
        return 1
    fi
}

# Test XRD Kubernetes resource validation
test_xrd_kubernetes_validation() {
    local failed_files=()
    
    for xrd_file in "$PACKAGES_DIR"/*/definition.yaml; do
        if [[ -f "$xrd_file" ]]; then
            if ! kubectl apply --dry-run=client -f "$xrd_file" >/dev/null 2>&1; then
                failed_files+=("$xrd_file")
            fi
        fi
    done
    
    if [[ ${#failed_files[@]} -eq 0 ]]; then
        return 0
    else
        log_error "Kubernetes validation errors in: ${failed_files[*]}"
        return 1
    fi
}

# Test XRD has required fields
test_xrd_required_fields() {
    local failed_files=()
    
    for xrd_file in "$PACKAGES_DIR"/*/definition.yaml; do
        if [[ -f "$xrd_file" ]]; then
            local component_name=$(basename "$(dirname "$xrd_file")")
            
            # Check required fields
            local missing_fields=()
            
            # Check apiVersion
            if ! yq eval '.apiVersion' "$xrd_file" | grep -q "apiextensions.crossplane.io"; then
                missing_fields+=("apiVersion")
            fi
            
            # Check kind
            if ! yq eval '.kind' "$xrd_file" | grep -q "CompositeResourceDefinition"; then
                missing_fields+=("kind")
            fi
            
            # Check metadata.name
            if [[ "$(yq eval '.metadata.name' "$xrd_file")" == "null" ]]; then
                missing_fields+=("metadata.name")
            fi
            
            # Check spec.group
            if [[ "$(yq eval '.spec.group' "$xrd_file")" == "null" ]]; then
                missing_fields+=("spec.group")
            fi
            
            # Check spec.names
            if [[ "$(yq eval '.spec.names' "$xrd_file")" == "null" ]]; then
                missing_fields+=("spec.names")
            fi
            
            # Check spec.versions
            if [[ "$(yq eval '.spec.versions' "$xrd_file")" == "null" ]]; then
                missing_fields+=("spec.versions")
            fi
            
            if [[ ${#missing_fields[@]} -ne 0 ]]; then
                failed_files+=("$xrd_file (missing: ${missing_fields[*]})")
            fi
        fi
    done
    
    if [[ ${#failed_files[@]} -eq 0 ]]; then
        return 0
    else
        log_error "Missing required fields in: ${failed_files[*]}"
        return 1
    fi
}

# Test XRD naming convention
test_xrd_naming_convention() {
    local failed_files=()
    
    for xrd_file in "$PACKAGES_DIR"/*/definition.yaml; do
        if [[ -f "$xrd_file" ]]; then
            local component_name=$(basename "$(dirname "$xrd_file")")
            local xrd_name=$(yq eval '.metadata.name' "$xrd_file")
            local expected_name=""
            
            case "$component_name" in
                "resourcegroup")
                    expected_name="xresourcegroups.astra.platform"
                    ;;
                "managedidentity")
                    expected_name="xmanagedidentities.astra.platform"
                    ;;
                "keyvault")
                    expected_name="xkeyvaults.astra.platform"
                    ;;
                "storage")
                    expected_name="xstorageaccounts.astra.platform"
                    ;;
                "containerregistry")
                    expected_name="xcontainerregistries.astra.platform"
                    ;;
                "containerapp")
                    expected_name="xcontainerapps.astra.platform"
                    ;;
                "platform")
                    expected_name="xplatforms.astra.platform"
                    ;;
            esac
            
            if [[ "$xrd_name" != "$expected_name" ]]; then
                failed_files+=("$xrd_file (expected: $expected_name, got: $xrd_name)")
            fi
        fi
    done
    
    if [[ ${#failed_files[@]} -eq 0 ]]; then
        return 0
    else
        log_error "Naming convention violations: ${failed_files[*]}"
        return 1
    fi
}

# Test XRD parameter schemas
test_xrd_parameter_schemas() {
    local failed_files=()
    
    for xrd_file in "$PACKAGES_DIR"/*/definition.yaml; do
        if [[ -f "$xrd_file" ]]; then
            local component_name=$(basename "$(dirname "$xrd_file")")
            
            # Check if parameters section exists
            local parameters_schema=$(yq eval '.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.parameters' "$xrd_file")
            
            if [[ "$parameters_schema" == "null" ]]; then
                failed_files+=("$xrd_file (missing parameters schema)")
                continue
            fi
            
            # Check for required environment parameter
            local environment_type=$(yq eval '.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.parameters.properties.environment.type' "$xrd_file")
            if [[ "$environment_type" != "string" ]]; then
                failed_files+=("$xrd_file (missing environment parameter)")
            fi
            
            # Check for required location parameter  
            local location_type=$(yq eval '.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.parameters.properties.location.type' "$xrd_file")
            if [[ "$location_type" != "string" ]]; then
                failed_files+=("$xrd_file (missing location parameter)")
            fi
        fi
    done
    
    if [[ ${#failed_files[@]} -eq 0 ]]; then
        return 0
    else
        log_error "Parameter schema issues: ${failed_files[*]}"
        return 1
    fi
}

# Test XRD composition references
test_xrd_composition_references() {
    local failed_files=()
    
    for xrd_file in "$PACKAGES_DIR"/*/definition.yaml; do
        if [[ -f "$xrd_file" ]]; then
            local component_name=$(basename "$(dirname "$xrd_file")")
            local composition_file="$(dirname "$xrd_file")/composition.yaml"
            
            # Check if corresponding composition exists
            if [[ ! -f "$composition_file" ]]; then
                failed_files+=("$xrd_file (missing composition: $composition_file)")
                continue
            fi
            
            # Check if composition references the XRD
            local xrd_name=$(yq eval '.metadata.name' "$xrd_file")
            local composition_compositeTypeRef=$(yq eval '.spec.compositeTypeRef.apiVersion + "/" + .spec.compositeTypeRef.kind' "$composition_file")
            local expected_ref="astra.platform/v1alpha1/"$(yq eval '.spec.names.kind' "$xrd_file")
            
            if [[ "$composition_compositeTypeRef" != "$expected_ref" ]]; then
                failed_files+=("$composition_file (incorrect XRD reference)")
            fi
        fi
    done
    
    if [[ ${#failed_files[@]} -eq 0 ]]; then
        return 0
    else
        log_error "Composition reference issues: ${failed_files[*]}"
        return 1
    fi
}

# Test environment parameter validation
test_environment_parameter_validation() {
    local failed_files=()
    
    for xrd_file in "$PACKAGES_DIR"/*/definition.yaml; do
        if [[ -f "$xrd_file" ]]; then
            # Check if environment parameter has enum constraint
            local environment_enum=$(yq eval '.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.parameters.properties.environment.enum' "$xrd_file")
            
            if [[ "$environment_enum" == "null" ]]; then
                failed_files+=("$xrd_file (missing environment enum)")
                continue
            fi
            
            # Check if enum contains required values
            local required_envs=("dev" "staging" "prod" "qa")
            for env in "${required_envs[@]}"; do
                if ! echo "$environment_enum" | grep -q "$env"; then
                    failed_files+=("$xrd_file (missing $env in environment enum)")
                fi
            done
        fi
    done
    
    if [[ ${#failed_files[@]} -eq 0 ]]; then
        return 0
    else
        log_error "Environment parameter validation issues: ${failed_files[*]}"
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting XRD validation tests..."
    log_info "Testing XRDs in: $PACKAGES_DIR"
    
    # Check prerequisites
    if ! command -v kubectl >/dev/null 2>&1; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    if ! command -v yq >/dev/null 2>&1; then
        log_error "yq not found. Please install yq."
        exit 1
    fi
    
    # Run all tests
    run_test "XRD YAML Syntax" test_xrd_yaml_syntax
    run_test "XRD Kubernetes Validation" test_xrd_kubernetes_validation
    run_test "XRD Required Fields" test_xrd_required_fields
    run_test "XRD Naming Convention" test_xrd_naming_convention
    run_test "XRD Parameter Schemas" test_xrd_parameter_schemas
    run_test "XRD Composition References" test_xrd_composition_references
    run_test "Environment Parameter Validation" test_environment_parameter_validation
    
    # Print summary
    echo
    log_info "Test Summary:"
    echo "  Tests Run: $TESTS_RUN"
    echo "  Tests Passed: $TESTS_PASSED"
    echo "  Tests Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All XRD validation tests passed!"
        exit 0
    else
        log_error "Some XRD validation tests failed!"
        exit 1
    fi
}

# Run main function
main "$@"