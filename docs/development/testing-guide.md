# Testing Infrastructure

Comprehensive testing suite for the Astra Platform including unit tests, integration tests, and end-to-end testing.

## 📋 Test Structure

```
tests/
├── unit/                    # Unit tests for individual components
│   ├── xrd-validation/      # XRD schema validation tests
│   ├── composition-tests/   # Composition logic tests
│   └── script-tests/        # Shell script unit tests
├── integration/             # Integration tests with Azure services
│   ├── azure-resources/     # Azure resource creation/deletion tests
│   ├── crossplane-tests/    # Crossplane provider integration tests
│   └── security-tests/      # Security and compliance tests
├── e2e/                     # End-to-end deployment tests
│   ├── environment-tests/   # Full environment deployment tests
│   ├── application-tests/   # Application deployment and testing
│   └── performance-tests/   # Load and performance testing
└── test-data/              # Test fixtures and mock data
    ├── fixtures/           # Sample configurations and data
    ├── mocks/              # Mock responses and test doubles
    └── scenarios/          # Test scenario definitions
```

## 🧪 Test Categories

### Unit Tests
- **XRD Validation**: Schema validation and parameter testing
- **Composition Testing**: Logic validation and resource mapping
- **Script Testing**: Shell script functionality and error handling
- **Configuration Testing**: YAML syntax and structure validation

### Integration Tests  
- **Azure Resource Tests**: Real Azure resource lifecycle testing
- **Crossplane Integration**: Provider functionality and reconciliation
- **Security Tests**: Authentication, authorization, and compliance
- **Network Tests**: Connectivity and ingress validation

### End-to-End Tests
- **Environment Deployment**: Complete environment setup and teardown
- **Application Testing**: Full application deployment workflow
- **Performance Testing**: Load testing and resource utilization
- **Disaster Recovery**: Backup and recovery testing

## 🚀 Running Tests

### Prerequisites
```bash
# Install test dependencies
./scripts/install-test-deps.sh

# Set up test environment
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_TENANT_ID="your-tenant-id"
export TEST_RESOURCE_GROUP="astra-test-rg"
```

### Unit Tests
```bash
# Run all unit tests
./scripts/test.sh unit

# Run specific test category
./scripts/test.sh unit xrd-validation
./scripts/test.sh unit composition-tests
./scripts/test.sh unit script-tests
```

### Integration Tests
```bash
# Run all integration tests (requires Azure access)
./scripts/test.sh integration

# Run specific integration tests
./scripts/test.sh integration azure-resources
./scripts/test.sh integration crossplane-tests
./scripts/test.sh integration security-tests
```

### End-to-End Tests
```bash
# Run complete e2e test suite
./scripts/test.sh e2e

# Run specific e2e tests
./scripts/test.sh e2e environment-tests
./scripts/test.sh e2e application-tests
./scripts/test.sh e2e performance-tests
```

### All Tests
```bash
# Run complete test suite
./scripts/test-all.sh

# Run tests with coverage
./scripts/test-all.sh --coverage

# Run tests in parallel
./scripts/test-all.sh --parallel
```

## 📊 Test Reporting

Tests generate comprehensive reports including:
- **Test Results**: Pass/fail status with detailed output
- **Coverage Reports**: Code and configuration coverage metrics
- **Performance Metrics**: Resource utilization and timing data
- **Security Scan Results**: Vulnerability and compliance reports

Reports are available in:
- `tests/reports/` - Local test reports
- Azure DevOps artifacts - CI/CD test results
- Azure DevOps test results - Pipeline integration

## 🛠️ Test Development

### Writing Unit Tests
See individual test directories for examples:
- [XRD Validation Tests](unit/xrd-validation/README.md)
- [Composition Tests](unit/composition-tests/README.md)
- [Script Tests](unit/script-tests/README.md)

### Writing Integration Tests
See integration test documentation:
- [Azure Resource Tests](integration/azure-resources/README.md)
- [Crossplane Tests](integration/crossplane-tests/README.md)
- [Security Tests](integration/security-tests/README.md)

### Writing E2E Tests
See end-to-end test guides:
- [Environment Tests](e2e/environment-tests/README.md)
- [Application Tests](e2e/application-tests/README.md)
- [Performance Tests](e2e/performance-tests/README.md)

## 🔧 Test Configuration

### Environment Variables
```bash
# Azure Configuration
AZURE_SUBSCRIPTION_ID="your-subscription-id"
AZURE_TENANT_ID="your-tenant-id"
AZURE_CLIENT_ID="test-sp-client-id"
AZURE_CLIENT_SECRET="test-sp-secret"

# Test Configuration
TEST_ENVIRONMENT="test"
TEST_RESOURCE_GROUP="astra-test-rg"
TEST_LOCATION="Central India"
TEST_TIMEOUT="600s"

# Cleanup Configuration
CLEANUP_AFTER_TESTS="true"
PRESERVE_ON_FAILURE="true"
```

### Test Data
Test fixtures and mock data are located in `test-data/`:
- **fixtures/**: Sample configurations and expected outputs
- **mocks/**: Mock Azure API responses
- **scenarios/**: Test scenario definitions

## 🚨 Continuous Integration

Tests are automatically run in CI/CD pipelines:

### Azure DevOps Pipeline
- **PR Validation**: Unit and integration tests on pull requests
- **Nightly Tests**: Complete e2e test suite
- **Release Testing**: Full test suite before releases

### Manual Testing
```bash
# Quick validation
make test-quick

# Full test suite
make test-all

# Specific environment testing
make test-env ENV=staging
```

## 📚 Test Documentation

Each test directory contains:
- **README.md**: Test overview and running instructions
- **CONTRIBUTING.md**: Guidelines for adding new tests
- **examples/**: Example test cases and patterns

## 🔍 Debugging Tests

### Debug Mode
```bash
# Run tests with debug output
DEBUG=true ./scripts/test.sh unit

# Run specific test with verbose output
./scripts/test.sh integration azure-resources --verbose

# Keep test resources for inspection
CLEANUP_AFTER_TESTS=false ./scripts/test.sh e2e
```

### Test Logs
Test logs are available at:
- `tests/logs/` - Local test execution logs
- Azure DevOps logs - CI/CD test output
- Azure resources - Test infrastructure logs

## 🚀 Contributing

To contribute to the test suite:

1. **Add Unit Tests**: For new XRDs, Compositions, or scripts
2. **Add Integration Tests**: For new Azure resource integrations
3. **Add E2E Tests**: For new deployment scenarios
4. **Update Documentation**: Keep test documentation current

See [Contributing Guidelines](../docs/development/contributing.md) for detailed instructions.

---

*This testing infrastructure ensures the reliability, security, and performance of the Astra Platform across all environments and deployment scenarios.*