# XRD Validation Tests

Unit tests for validating Custom Resource Definitions (XRDs) in the Astra Platform.

## 📋 Test Overview

These tests validate:
- XRD schema correctness
- Parameter validation
- Required field enforcement
- Default value assignment
- Schema constraints
- Cross-reference validation

## 🧪 Test Categories

### Schema Validation Tests
- **syntax-tests.sh**: YAML syntax and structure validation
- **schema-tests.sh**: OpenAPI schema validation
- **parameter-tests.sh**: Parameter definition and validation
- **constraint-tests.sh**: Field constraints and validation rules

### Cross-Reference Tests
- **dependency-tests.sh**: Resource dependency validation
- **composition-tests.sh**: XRD to Composition mapping validation
- **claim-tests.sh**: Platform claim validation

## 🚀 Running Tests

### All XRD Validation Tests
```bash
# From project root
./scripts/test.sh unit xrd-validation

# From this directory
./run-tests.sh
```

### Individual Test Categories
```bash
# Schema validation only
./syntax-tests.sh

# Parameter validation
./parameter-tests.sh

# Dependency validation
./dependency-tests.sh
```

## 📊 Test Data

Test data is organized as follows:
```
test-data/
├── valid-xrds/           # Valid XRD examples
├── invalid-xrds/         # Invalid XRD examples for negative testing
├── schema-fixtures/      # Schema validation fixtures
└── parameter-fixtures/   # Parameter validation test cases
```

## ✅ Expected Outcomes

### Valid XRDs Should:
- Pass YAML syntax validation
- Conform to Crossplane XRD schema
- Have all required fields defined
- Have proper parameter validation rules
- Reference valid composition names

### Invalid XRDs Should:
- Fail validation with clear error messages
- Be caught by schema validation
- Trigger parameter validation errors
- Show dependency resolution failures

## 🔧 Test Configuration

### Environment Variables
```bash
# Test configuration
XRD_TEST_TIMEOUT=60
XRD_VALIDATION_STRICT=true
KUBEBUILDER_ASSETS="/usr/local/bin"

# Kubernetes configuration
KUBECONFIG="~/.kube/config"
KUBECTL_CONTEXT="minikube"
```

### Test Dependencies
- kubectl
- yq (for YAML processing)
- openapi-generator (for schema validation)
- kubebuilder (for CRD validation)

## 📚 Test Examples

### Valid XRD Test
```yaml
# test-data/valid-xrds/platform-xrd.yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xplatforms.astra.platform
spec:
  group: astra.platform
  names:
    kind: XPlatform
    plural: xplatforms
  versions:
  - name: v1alpha1
    served: true
    referenceable: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              parameters:
                type: object
                properties:
                  environment:
                    type: string
                    enum: ["dev", "staging", "prod", "qa"]
                required:
                - environment
```

### Invalid XRD Test
```yaml
# test-data/invalid-xrds/missing-required-field.yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xplatforms.astra.platform
spec:
  group: astra.platform
  names:
    kind: XPlatform
    plural: xplatforms
  # Missing versions field - should fail validation
```

## 🐛 Common Test Issues

### Schema Validation Failures
- Missing required fields in XRD definition
- Invalid OpenAPI schema syntax
- Incorrect parameter types or constraints

### Parameter Validation Issues
- Missing required parameters
- Invalid parameter constraints
- Conflicting default values

### Dependency Issues
- References to non-existent compositions
- Circular dependencies between resources
- Missing composition templates

## 📖 Adding New Tests

### For New XRDs
1. Add valid XRD example to `test-data/valid-xrds/`
2. Add corresponding invalid examples to `test-data/invalid-xrds/`
3. Update `parameter-tests.sh` with parameter validation tests
4. Add dependency tests to `dependency-tests.sh`

### For New Parameters
1. Add parameter fixtures to `test-data/parameter-fixtures/`
2. Update `parameter-tests.sh` with new test cases
3. Add constraint validation tests to `constraint-tests.sh`

### Test Template
```bash
#!/bin/bash
# Test: XRD validation for [component]
# Description: [test description]

test_xrd_validation() {
    local xrd_file="$1"
    local expected_result="$2"
    
    if kubectl apply --dry-run=client -f "$xrd_file" >/dev/null 2>&1; then
        if [[ "$expected_result" == "valid" ]]; then
            echo "PASS: $xrd_file validation succeeded"
            return 0
        else
            echo "FAIL: $xrd_file should have failed validation"
            return 1
        fi
    else
        if [[ "$expected_result" == "invalid" ]]; then
            echo "PASS: $xrd_file validation failed as expected"
            return 0
        else
            echo "FAIL: $xrd_file validation failed unexpectedly"
            return 1
        fi
    fi
}
```

## 🔍 Debugging Tests

### Enable Debug Mode
```bash
# Run with debug output
DEBUG=true ./run-tests.sh

# Run specific test with verbose output
VERBOSE=true ./parameter-tests.sh
```

### Check Test Logs
```bash
# View test execution logs
cat ../../../logs/xrd-validation-unit.log

# Check specific test output
tail -f test-output.log
```

### Manual Validation
```bash
# Validate XRD manually
kubectl apply --dry-run=client -f test-data/valid-xrds/platform-xrd.yaml

# Check XRD schema
yq eval '.spec.versions[0].schema.openAPIV3Schema' test-data/valid-xrds/platform-xrd.yaml
```

---

*These tests ensure that all XRDs in the Astra Platform are correctly defined and follow Crossplane best practices.*