#!/bin/bash
set -euo pipefail

# Comprehensive Test Runner for Astra Platform
# Runs all test categories: unit, integration, and e2e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test configuration
RUN_UNIT_TESTS="${RUN_UNIT_TESTS:-true}"
RUN_INTEGRATION_TESTS="${RUN_INTEGRATION_TESTS:-true}"
RUN_E2E_TESTS="${RUN_E2E_TESTS:-true}"
PARALLEL_TESTS="${PARALLEL_TESTS:-false}"
COVERAGE_ENABLED="${COVERAGE_ENABLED:-false}"
STOP_ON_FAILURE="${STOP_ON_FAILURE:-false}"

# Test results
UNIT_RESULT=0
INTEGRATION_RESULT=0
E2E_RESULT=0
OVERALL_RESULT=0

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

# Show help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Comprehensive test runner for the Astra Platform

Options:
    --unit-only         Run only unit tests
    --integration-only  Run only integration tests  
    --e2e-only         Run only end-to-end tests
    --no-unit          Skip unit tests
    --no-integration   Skip integration tests
    --no-e2e           Skip end-to-end tests
    --parallel         Run tests in parallel where possible
    --coverage         Generate coverage reports
    --stop-on-failure  Stop execution on first test failure
    --help, -h         Show this help message

Environment Variables:
    RUN_UNIT_TESTS=true|false          Enable/disable unit tests
    RUN_INTEGRATION_TESTS=true|false   Enable/disable integration tests  
    RUN_E2E_TESTS=true|false          Enable/disable e2e tests
    PARALLEL_TESTS=true|false         Enable parallel test execution
    COVERAGE_ENABLED=true|false       Enable coverage reporting
    STOP_ON_FAILURE=true|false        Stop on first failure

Examples:
    $0                          # Run all tests
    $0 --unit-only             # Run only unit tests
    $0 --no-e2e               # Run unit and integration tests
    $0 --parallel --coverage   # Run all tests in parallel with coverage
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unit-only)
                RUN_UNIT_TESTS=true
                RUN_INTEGRATION_TESTS=false
                RUN_E2E_TESTS=false
                shift
                ;;
            --integration-only)
                RUN_UNIT_TESTS=false
                RUN_INTEGRATION_TESTS=true
                RUN_E2E_TESTS=false
                shift
                ;;
            --e2e-only)
                RUN_UNIT_TESTS=false
                RUN_INTEGRATION_TESTS=false
                RUN_E2E_TESTS=true
                shift
                ;;
            --no-unit)
                RUN_UNIT_TESTS=false
                shift
                ;;
            --no-integration)
                RUN_INTEGRATION_TESTS=false
                shift
                ;;
            --no-e2e)
                RUN_E2E_TESTS=false
                shift
                ;;
            --parallel)
                PARALLEL_TESTS=true
                shift
                ;;
            --coverage)
                COVERAGE_ENABLED=true
                shift
                ;;
            --stop-on-failure)
                STOP_ON_FAILURE=true
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

# Check if test script is available
check_test_script() {
    if [[ ! -f "$SCRIPT_DIR/test.sh" ]]; then
        log_error "Test script not found: $SCRIPT_DIR/test.sh"
        return 1
    fi
    
    if [[ ! -x "$SCRIPT_DIR/test.sh" ]]; then
        log_error "Test script not executable: $SCRIPT_DIR/test.sh"
        return 1
    fi
    
    return 0
}

# Generate test report header
generate_report_header() {
    local report_file="$1"
    
    cat > "$report_file" << EOF
================================================================================
                        ASTRA PLATFORM TEST REPORT
================================================================================

Test Run Information:
  Date/Time: $(date)
  Test Configuration:
    - Unit Tests: $RUN_UNIT_TESTS
    - Integration Tests: $RUN_INTEGRATION_TESTS
    - E2E Tests: $RUN_E2E_TESTS
    - Parallel Execution: $PARALLEL_TESTS
    - Coverage Enabled: $COVERAGE_ENABLED
    - Stop on Failure: $STOP_ON_FAILURE

Environment:
  - Platform: $(uname -s)
  - Architecture: $(uname -m)
  - Shell: $SHELL
  - Working Directory: $PWD

================================================================================

EOF
}

# Run unit tests
run_unit_tests() {
    log_info "Running unit tests..."
    
    local start_time=$(date +%s)
    
    if "$SCRIPT_DIR/test.sh" unit; then
        UNIT_RESULT=0
        log_success "Unit tests completed successfully"
    else
        UNIT_RESULT=1
        log_error "Unit tests failed"
        
        if [[ "$STOP_ON_FAILURE" == "true" ]]; then
            log_error "Stopping execution due to unit test failure"
            return 1
        fi
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_info "Unit tests completed in ${duration}s"
    
    return $UNIT_RESULT
}

# Run integration tests
run_integration_tests() {
    log_info "Running integration tests..."
    
    local start_time=$(date +%s)
    
    if "$SCRIPT_DIR/test.sh" integration; then
        INTEGRATION_RESULT=0
        log_success "Integration tests completed successfully"
    else
        INTEGRATION_RESULT=1
        log_error "Integration tests failed"
        
        if [[ "$STOP_ON_FAILURE" == "true" ]]; then
            log_error "Stopping execution due to integration test failure"
            return 1
        fi
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_info "Integration tests completed in ${duration}s"
    
    return $INTEGRATION_RESULT
}

# Run e2e tests
run_e2e_tests() {
    log_info "Running end-to-end tests..."
    
    local start_time=$(date +%s)
    
    if "$SCRIPT_DIR/test.sh" e2e; then
        E2E_RESULT=0
        log_success "End-to-end tests completed successfully"
    else
        E2E_RESULT=1
        log_error "End-to-end tests failed"
        
        if [[ "$STOP_ON_FAILURE" == "true" ]]; then
            log_error "Stopping execution due to e2e test failure"
            return 1
        fi
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_info "End-to-end tests completed in ${duration}s"
    
    return $E2E_RESULT
}

# Run tests in parallel
run_tests_parallel() {
    log_info "Running tests in parallel..."
    
    local pids=()
    local test_types=()
    
    # Start unit tests
    if [[ "$RUN_UNIT_TESTS" == "true" ]]; then
        (
            if "$SCRIPT_DIR/test.sh" unit > "tests/logs/unit-parallel.log" 2>&1; then
                echo "0" > "tests/reports/unit-result.txt"
            else
                echo "1" > "tests/reports/unit-result.txt"
            fi
        ) &
        pids+=($!)
        test_types+=("unit")
    fi
    
    # Start integration tests
    if [[ "$RUN_INTEGRATION_TESTS" == "true" ]]; then
        (
            if "$SCRIPT_DIR/test.sh" integration > "tests/logs/integration-parallel.log" 2>&1; then
                echo "0" > "tests/reports/integration-result.txt"
            else
                echo "1" > "tests/reports/integration-result.txt"
            fi
        ) &
        pids+=($!)
        test_types+=("integration")
    fi
    
    # E2E tests cannot run in parallel with others due to resource conflicts
    # They will run after unit and integration tests complete
    
    # Wait for unit and integration tests
    local failed_tests=()
    for i in "${!pids[@]}"; do
        local pid="${pids[$i]}"
        local test_type="${test_types[$i]}"
        
        if wait "$pid"; then
            log_success "$test_type tests completed (parallel)"
        else
            log_error "$test_type tests failed (parallel)"
            failed_tests+=("$test_type")
        fi
    done
    
    # Read results
    if [[ "$RUN_UNIT_TESTS" == "true" ]] && [[ -f "tests/reports/unit-result.txt" ]]; then
        UNIT_RESULT=$(cat "tests/reports/unit-result.txt")
    fi
    
    if [[ "$RUN_INTEGRATION_TESTS" == "true" ]] && [[ -f "tests/reports/integration-result.txt" ]]; then
        INTEGRATION_RESULT=$(cat "tests/reports/integration-result.txt")
    fi
    
    # Run E2E tests sequentially after others complete
    if [[ "$RUN_E2E_TESTS" == "true" ]]; then
        run_e2e_tests
    fi
    
    # Check if we should stop on failure
    if [[ ${#failed_tests[@]} -gt 0 ]] && [[ "$STOP_ON_FAILURE" == "true" ]]; then
        log_error "Stopping due to failed tests: ${failed_tests[*]}"
        return 1
    fi
    
    return 0
}

# Run tests sequentially
run_tests_sequential() {
    log_info "Running tests sequentially..."
    
    # Run unit tests
    if [[ "$RUN_UNIT_TESTS" == "true" ]]; then
        if ! run_unit_tests; then
            return 1
        fi
    fi
    
    # Run integration tests
    if [[ "$RUN_INTEGRATION_TESTS" == "true" ]]; then
        if ! run_integration_tests; then
            return 1
        fi
    fi
    
    # Run e2e tests
    if [[ "$RUN_E2E_TESTS" == "true" ]]; then
        if ! run_e2e_tests; then
            return 1
        fi
    fi
    
    return 0
}

# Generate coverage report
generate_coverage_report() {
    if [[ "$COVERAGE_ENABLED" != "true" ]]; then
        return 0
    fi
    
    log_info "Generating coverage report..."
    
    local coverage_file="tests/reports/coverage-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$coverage_file" << EOF
Astra Platform Test Coverage Report
==================================
Generated: $(date)

Coverage Summary:
- XRD Definitions: $(find packages -name "definition.yaml" | wc -l) files
- Compositions: $(find packages -name "composition.yaml" | wc -l) files
- Scripts: $(find scripts -name "*.sh" | wc -l) files
- Test Files: $(find tests -name "*.sh" | wc -l) files

Test Categories Executed:
- Unit Tests: $([[ "$RUN_UNIT_TESTS" == "true" ]] && echo "✓" || echo "✗")
- Integration Tests: $([[ "$RUN_INTEGRATION_TESTS" == "true" ]] && echo "✓" || echo "✗")
- E2E Tests: $([[ "$RUN_E2E_TESTS" == "true" ]] && echo "✓" || echo "✗")

Test Results:
- Unit Test Result: $([[ $UNIT_RESULT -eq 0 ]] && echo "PASS" || echo "FAIL")
- Integration Test Result: $([[ $INTEGRATION_RESULT -eq 0 ]] && echo "PASS" || echo "FAIL")
- E2E Test Result: $([[ $E2E_RESULT -eq 0 ]] && echo "PASS" || echo "FAIL")

Overall Result: $([[ $OVERALL_RESULT -eq 0 ]] && echo "PASS" || echo "FAIL")
EOF
    
    log_info "Coverage report generated: $coverage_file"
    
    return 0
}

# Generate final test report
generate_final_report() {
    local report_file="tests/reports/test-all-$(date +%Y%m%d-%H%M%S).txt"
    
    # Create reports directory if it doesn't exist
    mkdir -p "tests/reports"
    
    generate_report_header "$report_file"
    
    cat >> "$report_file" << EOF
TEST RESULTS:
================================================================================

Unit Tests:        $([[ "$RUN_UNIT_TESTS" == "true" ]] && ([[ $UNIT_RESULT -eq 0 ]] && echo "PASS" || echo "FAIL") || echo "SKIPPED")
Integration Tests: $([[ "$RUN_INTEGRATION_TESTS" == "true" ]] && ([[ $INTEGRATION_RESULT -eq 0 ]] && echo "PASS" || echo "FAIL") || echo "SKIPPED")
E2E Tests:         $([[ "$RUN_E2E_TESTS" == "true" ]] && ([[ $E2E_RESULT -eq 0 ]] && echo "PASS" || echo "FAIL") || echo "SKIPPED")

Overall Result:    $([[ $OVERALL_RESULT -eq 0 ]] && echo "PASS" || echo "FAIL")

================================================================================

Test Logs:
$(ls -la tests/logs/*.log 2>/dev/null | tail -10 || echo "No log files found")

Test Reports:
$(ls -la tests/reports/*.txt 2>/dev/null | tail -5 || echo "No report files found")

================================================================================
Test run completed at $(date)
================================================================================
EOF
    
    log_info "Final test report generated: $report_file"
    
    # Also output summary to console
    echo
    log_info "==============================================="
    log_info "           FINAL TEST RESULTS"
    log_info "==============================================="
    
    if [[ "$RUN_UNIT_TESTS" == "true" ]]; then
        if [[ $UNIT_RESULT -eq 0 ]]; then
            log_success "Unit Tests: PASSED"
        else
            log_error "Unit Tests: FAILED"
        fi
    else
        log_warning "Unit Tests: SKIPPED"
    fi
    
    if [[ "$RUN_INTEGRATION_TESTS" == "true" ]]; then
        if [[ $INTEGRATION_RESULT -eq 0 ]]; then
            log_success "Integration Tests: PASSED"
        else
            log_error "Integration Tests: FAILED"
        fi
    else
        log_warning "Integration Tests: SKIPPED"
    fi
    
    if [[ "$RUN_E2E_TESTS" == "true" ]]; then
        if [[ $E2E_RESULT -eq 0 ]]; then
            log_success "E2E Tests: PASSED"
        else
            log_error "E2E Tests: FAILED"
        fi
    else
        log_warning "E2E Tests: SKIPPED"
    fi
    
    echo
    if [[ $OVERALL_RESULT -eq 0 ]]; then
        log_success "OVERALL RESULT: ALL TESTS PASSED! 🎉"
    else
        log_error "OVERALL RESULT: SOME TESTS FAILED! ❌"
    fi
    log_info "==============================================="
    
    return 0
}

# Main execution function
main() {
    local start_time=$(date +%s)
    
    log_info "Starting comprehensive Astra Platform test suite..."
    log_info "Test configuration:"
    echo "  Unit Tests: $RUN_UNIT_TESTS"
    echo "  Integration Tests: $RUN_INTEGRATION_TESTS"
    echo "  E2E Tests: $RUN_E2E_TESTS"
    echo "  Parallel Execution: $PARALLEL_TESTS"
    echo "  Coverage Enabled: $COVERAGE_ENABLED"
    echo "  Stop on Failure: $STOP_ON_FAILURE"
    
    # Check prerequisites
    if ! check_test_script; then
        exit 1
    fi
    
    # Create necessary directories
    mkdir -p tests/logs tests/reports
    
    # Run tests
    if [[ "$PARALLEL_TESTS" == "true" ]]; then
        run_tests_parallel
    else
        run_tests_sequential
    fi
    
    # Calculate overall result
    OVERALL_RESULT=$((UNIT_RESULT + INTEGRATION_RESULT + E2E_RESULT))
    
    # Generate reports
    generate_coverage_report
    generate_final_report
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    log_info "Total test execution time: ${total_duration}s"
    
    # Exit with overall result
    exit $OVERALL_RESULT
}

# Parse arguments and run
parse_args "$@"
main