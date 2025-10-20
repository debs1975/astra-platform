# End-to-End Environment Tests

Complete end-to-end tests that validate full environment deployment workflows from infrastructure provisioning to application deployment and testing.

## 📋 Test Overview

These tests validate:
- Complete environment deployment workflows
- Multi-environment consistency
- Application deployment and functionality
- Environment-specific configurations
- Full lifecycle management (create → deploy → test → destroy)

## 🧪 Test Categories

### Environment Deployment Tests
- **dev-environment-test.sh**: Development environment deployment
- **staging-environment-test.sh**: Staging environment deployment  
- **prod-environment-test.sh**: Production environment deployment
- **multi-env-test.sh**: Multi-environment deployment workflow

### Application Deployment Tests
- **simple-app-test.sh**: Basic application deployment test
- **complex-app-test.sh**: Multi-container application deployment
- **database-app-test.sh**: Application with database dependencies
- **microservices-test.sh**: Microservices architecture deployment

### Workflow Tests
- **cicd-workflow-test.sh**: CI/CD pipeline simulation
- **blue-green-test.sh**: Blue-green deployment testing
- **rollback-test.sh**: Application rollback testing
- **disaster-recovery-test.sh**: Disaster recovery procedures

## 🚀 Running Tests

### All E2E Tests
```bash
# From project root
./scripts/test.sh e2e

# From this directory
./run-tests.sh
```

### Specific Environment Tests
```bash
# Development environment only
./scripts/test.sh e2e environment-tests

# Individual environment test
./dev-environment-test.sh
```

### Application Tests
```bash
# All application tests
./scripts/test.sh e2e application-tests

# Specific application test
./simple-app-test.sh
```

## 📋 Prerequisites

### Infrastructure Requirements
- Kubernetes cluster with Crossplane installed
- Azure subscription with sufficient quotas
- Service principal with appropriate permissions
- Local development tools (Docker, kubectl, Azure CLI)

### Environment Variables
```bash
# Required
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"

# Optional
export E2E_TEST_PREFIX="e2e"
export E2E_TEST_LOCATION="Central India"
export E2E_TEST_TIMEOUT="3600"  # 1 hour
export PRESERVE_ON_FAILURE="false"
```

### Test Applications
The tests use several test applications:
- **Simple Web App**: nginx-based simple web server
- **API Service**: Node.js REST API with health checks
- **Database App**: Application with PostgreSQL dependency
- **Microservices**: Multi-service application with service mesh

## 🏗️ Test Scenarios

### Complete Environment Test Flow
1. **Infrastructure Setup**: Deploy Crossplane platform resources
2. **Environment Creation**: Create environment-specific resources
3. **Application Deployment**: Deploy test application
4. **Functionality Testing**: Verify application functionality
5. **Scaling Tests**: Test auto-scaling capabilities
6. **Security Validation**: Verify security configurations
7. **Cleanup**: Remove all resources

### Multi-Environment Test Flow
1. **Sequential Deployment**: Deploy dev → staging → prod
2. **Configuration Validation**: Verify environment-specific settings
3. **Promotion Testing**: Test application promotion between environments
4. **Consistency Validation**: Ensure consistent behavior across environments

## 📊 Test Data and Fixtures

### Test Application Configurations
```
test-data/
├── applications/
│   ├── simple-web-app/
│   │   ├── Dockerfile
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── api-service/
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── k8s-manifests/
│   └── microservices/
│       ├── frontend/
│       ├── backend/
│       └── database/
├── environments/
│   ├── dev-config.yaml
│   ├── staging-config.yaml
│   └── prod-config.yaml
└── scenarios/
    ├── basic-deployment.yaml
    ├── scaling-test.yaml
    └── failure-scenarios.yaml
```

### Environment Configurations
```yaml
# test-data/environments/dev-config.yaml
environment: "dev"
namingPrefix: "e2etest"
location: "Central India"
containerApp:
  cpu: 0.25
  memory: "0.5Gi"
  minReplicas: 1
  maxReplicas: 3
security:
  enableKeyVault: true
storage:
  enableStorage: true
  accountType: "Standard_LRS"
containerRegistry:
  enableRegistry: true
  sku: "Basic"
```

## ✅ Test Validation

### Infrastructure Validation
```bash
# Verify all Azure resources exist
az resource list --resource-group "e2etest-dev-rg" --output table

# Check Crossplane resource status
kubectl get xplatform e2etest-dev-platform -n e2e-test-dev

# Validate resource configurations
az containerapp show --name "e2etest-dev-app" --resource-group "e2etest-dev-rg"
```

### Application Validation
```bash
# Check application health
APP_URL=$(kubectl get xplatform e2etest-dev-platform -n e2e-test-dev -o jsonpath='{.status.components.containerApp.applicationUrl}')
curl -f "$APP_URL/health"

# Validate application functionality
curl -f "$APP_URL/api/status"

# Test application scaling
kubectl patch xplatform e2etest-dev-platform -n e2e-test-dev --type='json' -p='[{"op": "replace", "path": "/spec/parameters/containerApp/maxReplicas", "value": 5}]'
```

### Performance Validation
```bash
# Load testing
for i in {1..100}; do
  curl -s "$APP_URL" > /dev/null &
done
wait

# Monitor resource utilization
az monitor metrics list --resource "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/e2etest-dev-rg/providers/Microsoft.App/containerApps/e2etest-dev-app"
```

## 🔧 Test Configuration

### Simple Web App Test
```yaml
# Test application deployment configuration
apiVersion: astra.platform/v1alpha1
kind: XPlatform
metadata:
  name: e2etest-dev-platform
  namespace: e2e-test-dev
spec:
  parameters:
    environment: "dev"
    location: "Central India"
    namingPrefix: "e2etest"
    containerApp:
      image: "nginx:latest"
      cpu: 0.25
      memory: "0.5Gi"
      minReplicas: 1
      maxReplicas: 3
      ingress:
        external: true
        targetPort: 80
```

### API Service Test
```yaml
# API service with custom configuration
spec:
  parameters:
    containerApp:
      image: "e2etestacr.azurecr.io/api-service:latest"
      environmentVariables:
        - name: "NODE_ENV"
          value: "production"
        - name: "PORT"
          value: "3000"
        - name: "DATABASE_URL"
          secretRef: "database-connection-string"
      ingress:
        external: true
        targetPort: 3000
```

## 🚨 Error Scenarios and Recovery

### Failure Scenarios Tested
1. **Azure Quota Exceeded**: Test behavior when quotas are exceeded
2. **Network Connectivity Issues**: Test network failure recovery
3. **Container Image Pull Failures**: Test image pull error handling
4. **Resource Creation Failures**: Test resource creation error recovery
5. **Application Startup Failures**: Test application failure handling

### Recovery Testing
```bash
# Simulate container app failure
az containerapp update --name "e2etest-dev-app" --resource-group "e2etest-dev-rg" --image "invalid-image:latest"

# Verify automatic recovery
kubectl describe xplatform e2etest-dev-platform -n e2e-test-dev

# Test manual recovery
kubectl patch xplatform e2etest-dev-platform -n e2e-test-dev --type='json' -p='[{"op": "replace", "path": "/spec/parameters/containerApp/image", "value": "nginx:latest"}]'
```

## 🧹 Cleanup and Resource Management

### Automatic Cleanup
Tests automatically clean up resources unless `PRESERVE_ON_FAILURE=true` is set for debugging.

### Manual Cleanup
```bash
# Delete test platforms
kubectl delete xplatform --all -n e2e-test-dev
kubectl delete xplatform --all -n e2e-test-staging
kubectl delete xplatform --all -n e2e-test-prod

# Force cleanup Azure resources
az group delete --name "e2etest-dev-rg" --yes --no-wait
az group delete --name "e2etest-staging-rg" --yes --no-wait
az group delete --name "e2etest-prod-rg" --yes --no-wait
```

### Resource Monitoring
```bash
# Monitor resource cleanup
watch -n 10 'az group list --query "[?starts_with(name, '"'"'e2etest-'"'"')]" --output table'

# Check Kubernetes resources
kubectl get xplatform -A
kubectl get managed -A | grep e2etest
```

## 📈 Performance Metrics

### Deployment Timing Metrics
- **Environment Setup**: < 10 minutes
- **Application Deployment**: < 5 minutes  
- **First Request Response**: < 2 minutes after deployment
- **Auto-scaling Response**: < 5 minutes under load
- **Complete Cleanup**: < 15 minutes

### Resource Utilization Metrics
- **CPU Utilization**: Monitor during load tests
- **Memory Usage**: Track memory consumption patterns
- **Network Latency**: Measure response times
- **Storage IOPS**: Monitor storage performance

## 🔍 Debugging E2E Tests

### Debug Mode
```bash
# Run with full debug output
DEBUG=true ./run-tests.sh

# Preserve resources on failure for inspection
PRESERVE_ON_FAILURE=true ./simple-app-test.sh
```

### Common Debug Commands
```bash
# Check Crossplane status
kubectl get providers -o wide
kubectl get managed -o wide
kubectl describe xplatform e2etest-dev-platform -n e2e-test-dev

# Check Azure resources
az group deployment list --resource-group "e2etest-dev-rg"
az containerapp logs show --name "e2etest-dev-app" --resource-group "e2etest-dev-rg"

# Application debugging
APP_URL=$(kubectl get xplatform e2etest-dev-platform -n e2e-test-dev -o jsonpath='{.status.components.containerApp.applicationUrl}')
curl -v "$APP_URL"
```

## 📚 Adding New E2E Tests

### For New Application Types
1. Create application source code in `test-data/applications/`
2. Build and push test image to registry
3. Create deployment configuration
4. Add validation scripts
5. Update main test runner

### For New Environment Scenarios
1. Create environment configuration in `test-data/environments/`
2. Add environment-specific validation
3. Create test scenario script
4. Add to CI/CD pipeline

### Test Template
```bash
#!/bin/bash
# E2E Test: [Test Name]
# Description: [Test description]

test_deployment() {
    # Deploy platform
    kubectl apply -f test-config.yaml
    
    # Wait for deployment
    kubectl wait --for=condition=Ready xplatform test-platform --timeout=600s
    
    # Validate deployment
    validate_application
    
    # Cleanup
    kubectl delete -f test-config.yaml
}
```

---

*These end-to-end tests provide comprehensive validation of the Astra Platform's ability to deploy and manage complete application environments from infrastructure provisioning through application deployment and operation.*