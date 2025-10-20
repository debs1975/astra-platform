# Azure Resource Integration Tests

Integration tests that validate Azure resource creation, configuration, and lifecycle management through Crossplane.

## 📋 Test Overview

These tests validate:
- Azure resource provisioning through Crossplane
- Resource configuration and updates
- Resource dependencies and relationships
- Azure service integration
- Resource cleanup and deletion

## 🧪 Test Categories

### Resource Lifecycle Tests
- **create-tests.sh**: Resource creation and initial configuration
- **update-tests.sh**: Resource updates and configuration changes
- **delete-tests.sh**: Resource cleanup and deletion
- **state-tests.sh**: State management and reconciliation

### Service Integration Tests
- **networking-tests.sh**: Virtual network and connectivity tests
- **security-tests.sh**: IAM, RBAC, and security configuration tests
- **storage-tests.sh**: Storage account and blob service tests
- **identity-tests.sh**: Managed identity and authentication tests

### Dependency Tests
- **dependency-order-tests.sh**: Resource dependency creation order
- **cross-reference-tests.sh**: Resource cross-references and relationships
- **failure-recovery-tests.sh**: Failure scenarios and recovery

## 🚀 Running Tests

### All Azure Resource Tests
```bash
# From project root
./scripts/test.sh integration azure-resources

# From this directory
./run-tests.sh
```

### Individual Test Categories
```bash
# Resource lifecycle only
./create-tests.sh

# Security integration
./security-tests.sh

# Dependency validation
./dependency-order-tests.sh
```

## 📋 Prerequisites

### Azure Requirements
- Azure subscription with sufficient permissions
- Service principal with Contributor role
- Resource group for testing (will be created/deleted)

### Environment Variables
```bash
# Required
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"

# Optional
export TEST_RESOURCE_GROUP="astra-integration-test-rg"
export TEST_LOCATION="Central India"
export TEST_TIMEOUT="1800"  # 30 minutes
```

### Tools Required
- Azure CLI (authenticated)
- kubectl (with Crossplane cluster access)
- jq (for JSON processing)
- curl (for API testing)

## 🏗️ Test Environment Setup

### Automatic Setup
The test runner automatically:
1. Creates test resource group
2. Sets up test namespace in Kubernetes
3. Applies test Crossplane resources
4. Waits for resource provisioning

### Manual Setup
```bash
# Create test resource group
az group create --name "$TEST_RESOURCE_GROUP" --location "$TEST_LOCATION"

# Create test namespace
kubectl create namespace astra-integration-test

# Apply test platform claim
kubectl apply -f test-data/test-platform-claim.yaml -n astra-integration-test
```

## 📊 Test Data

Test configurations and fixtures:
```
test-data/
├── platform-claims/        # Test platform configurations
├── resource-configs/       # Individual resource test configs
├── invalid-configs/        # Invalid configurations for negative testing
└── expected-outputs/       # Expected Azure resource states
```

## ✅ Test Scenarios

### Resource Creation Tests
1. **Basic Resource Creation**: Verify all resources are created
2. **Parameter Validation**: Test different parameter combinations
3. **Naming Convention**: Verify resource names follow patterns
4. **Tag Application**: Check resource tags are applied correctly

### Configuration Tests
1. **Environment Variables**: Test environment-specific configurations
2. **Security Settings**: Validate security configurations
3. **Network Configuration**: Test networking and connectivity
4. **Storage Configuration**: Validate storage account settings

### Integration Tests
1. **Container App Deployment**: End-to-end app deployment
2. **Secret Management**: Key Vault integration testing
3. **Image Registry**: ACR integration and image pull
4. **Identity Integration**: Managed identity authentication

### Failure Tests
1. **Invalid Configuration**: Test error handling
2. **Permission Errors**: Test insufficient permissions
3. **Resource Conflicts**: Test name conflicts and dependencies
4. **Network Failures**: Test connectivity issues

## 🔧 Test Configuration

### Test Platform Claim
```yaml
# test-data/platform-claims/basic-test-platform.yaml
apiVersion: astra.platform/v1alpha1
kind: XPlatform
metadata:
  name: integration-test-platform
  namespace: astra-integration-test
spec:
  parameters:
    environment: "test"
    location: "Central India"
    namingPrefix: "astratest"
    containerApp:
      image: "nginx:latest"
      cpu: 0.25
      memory: "0.5Gi"
      minReplicas: 1
      maxReplicas: 3
```

### Expected Resources
After deployment, the following Azure resources should exist:
- Resource Group: `astratest-test-rg`
- Managed Identity: `astratest-test-identity`
- Key Vault: `astratest-test-kv`
- Storage Account: `astratesttestst`
- Container Registry: `astratesttestacr`
- Container App: `astratest-test-app`

## 🔍 Test Validation

### Resource Existence Validation
```bash
# Check resource group
az group show --name "astratest-test-rg"

# Check managed identity
az identity show --name "astratest-test-identity" --resource-group "astratest-test-rg"

# Check container app
az containerapp show --name "astratest-test-app" --resource-group "astratest-test-rg"
```

### Configuration Validation
```bash
# Verify container app configuration
APP_CONFIG=$(az containerapp show --name "astratest-test-app" --resource-group "astratest-test-rg")

# Check CPU allocation
echo "$APP_CONFIG" | jq '.properties.template.containers[0].resources.cpu'

# Check memory allocation
echo "$APP_CONFIG" | jq '.properties.template.containers[0].resources.memory'

# Check replica configuration
echo "$APP_CONFIG" | jq '.properties.template.scale'
```

### Connectivity Validation
```bash
# Get application URL
APP_URL=$(az containerapp show --name "astratest-test-app" --resource-group "astratest-test-rg" --query "properties.configuration.ingress.fqdn" -o tsv)

# Test application accessibility
curl -f "https://$APP_URL" || echo "Application not accessible"

# Test SSL certificate
curl -I "https://$APP_URL" | grep -i "HTTP/2 200"
```

## 🚨 Error Handling

### Common Issues
1. **Azure Quota Limits**: Check subscription quotas
2. **Permission Errors**: Verify service principal permissions
3. **Resource Conflicts**: Check for existing resources with same names
4. **Network Connectivity**: Verify Azure API accessibility

### Debugging Commands
```bash
# Check Crossplane provider status
kubectl get providers

# Check managed resources
kubectl get managed

# Check Azure deployment status
az deployment group list --resource-group "$TEST_RESOURCE_GROUP"

# View Crossplane logs
kubectl logs -f deployment/crossplane-provider-azure -n crossplane-system
```

### Test Recovery
```bash
# Clean up failed test resources
./cleanup-test-resources.sh

# Restart provider if needed
kubectl delete pod -l pkg.crossplane.io/provider=provider-azure -n crossplane-system

# Re-run specific test
./create-tests.sh --resource-group "$TEST_RESOURCE_GROUP"
```

## 🧹 Cleanup

### Automatic Cleanup
Tests automatically clean up resources unless `CLEANUP_AFTER_TESTS=false` is set.

### Manual Cleanup
```bash
# Delete test platform
kubectl delete xplatform integration-test-platform -n astra-integration-test

# Wait for Azure resources to be deleted
kubectl wait --for=delete xplatform integration-test-platform -n astra-integration-test --timeout=600s

# Force delete resource group if needed
az group delete --name "$TEST_RESOURCE_GROUP" --yes --no-wait
```

## 📈 Performance Metrics

Tests collect the following metrics:
- **Resource Creation Time**: Time to provision each resource type
- **Platform Ready Time**: Time for complete platform to be ready
- **Application Start Time**: Time for container app to start serving traffic
- **Cleanup Time**: Time to delete all resources

### Metric Thresholds
- Resource Group: < 30 seconds
- Managed Identity: < 60 seconds
- Key Vault: < 120 seconds
- Storage Account: < 180 seconds
- Container Registry: < 240 seconds
- Container App: < 300 seconds
- Complete Platform: < 600 seconds

## 📚 Adding New Tests

### For New Azure Resources
1. Add resource configuration to `test-data/resource-configs/`
2. Create validation script in appropriate test category
3. Update `run-tests.sh` to include new test
4. Add cleanup logic for new resource type

### For New Integration Scenarios
1. Create new test script following naming convention
2. Add test data fixtures
3. Update main test runner
4. Document expected behavior and validation steps

---

*These integration tests ensure that the Astra Platform correctly provisions and manages Azure resources through Crossplane, validating both happy path scenarios and error conditions.*