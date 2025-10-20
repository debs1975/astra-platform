#!/bin/bash
set -euo pipefail

# Test Data Setup Script for Astra Platform
# Creates sample test data and configurations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Create test data directory structure
create_test_directories() {
    log_info "Creating test data directories..."
    
    mkdir -p tests/data/unit
    mkdir -p tests/data/integration
    mkdir -p tests/data/e2e
    mkdir -p tests/data/fixtures
    mkdir -p tests/data/templates
    mkdir -p tests/data/configs
    mkdir -p tests/results
    mkdir -p tests/logs
    mkdir -p tests/reports
    
    log_success "Test directories created"
}

# Create unit test data
create_unit_test_data() {
    log_info "Creating unit test data..."
    
    # Sample valid XRD for testing
    cat > tests/data/unit/valid-xrd.yaml << 'EOF'
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: astra-test-resources.platform.astra.dev
spec:
  group: platform.astra.dev
  names:
    kind: AstraTestResource
    plural: astra-test-resources
  claimNames:
    kind: AstraTestResourceClaim
    plural: astra-test-resource-claims
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
              environment:
                type: string
                enum: ["dev", "staging", "prod"]
              region:
                type: string
                default: "centralindia"
          status:
            type: object
EOF

    # Sample invalid XRD for testing
    cat > tests/data/unit/invalid-xrd.yaml << 'EOF'
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: invalid-xrd
# Missing required spec section
EOF

    # Sample composition for testing
    cat > tests/data/unit/valid-composition.yaml << 'EOF'
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: test-composition
  labels:
    provider: azure
    service: test
spec:
  writeConnectionSecretsToNamespace: crossplane-system
  compositeTypeRef:
    apiVersion: platform.astra.dev/v1alpha1
    kind: AstraTestResource
  resources:
  - name: test-resource
    base:
      apiVersion: azure.crossplane.io/v1beta1
      kind: ResourceGroup
      spec:
        forProvider:
          location: Central India
        providerConfigRef:
          name: azure-provider-config
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: spec.environment
      toFieldPath: metadata.labels['environment']
EOF

    log_success "Unit test data created"
}

# Create integration test data
create_integration_test_data() {
    log_info "Creating integration test data..."
    
    # Sample platform claim for integration testing
    cat > tests/data/integration/platform-claim-dev.yaml << 'EOF'
apiVersion: platform.astra.dev/v1alpha1
kind: PlatformClaim
metadata:
  name: test-platform-dev
  namespace: default
spec:
  environment: dev
  region: centralindia
  resourceGroupName: astra-test-dev-rg
  tags:
    environment: dev
    project: astra-platform-test
    owner: test-automation
  containerApps:
    enabled: true
    environmentName: astra-test-dev-env
  containerRegistry:
    enabled: true
    name: astratestdevcr
    sku: Basic
  keyVault:
    enabled: true
    name: astra-test-dev-kv
    sku: standard
  storage:
    enabled: true
    accountName: astratestdevst
    accountType: Standard_LRS
  managedIdentity:
    enabled: true
    name: astra-test-dev-identity
EOF

    # Sample Azure resource configurations
    cat > tests/data/integration/azure-resources.json << 'EOF'
{
  "resourceGroup": {
    "name": "astra-test-integration-rg",
    "location": "centralindia",
    "tags": {
      "environment": "test",
      "purpose": "integration-testing"
    }
  },
  "containerRegistry": {
    "name": "astratestintegrationcr",
    "sku": "Basic",
    "adminUserEnabled": false
  },
  "keyVault": {
    "name": "astra-test-int-kv",
    "sku": "standard",
    "enabledForDeployment": true,
    "enabledForTemplateDeployment": true
  },
  "storage": {
    "accountName": "astratestintegrationst",
    "accountType": "Standard_LRS",
    "enableBlobPublicAccess": false
  },
  "managedIdentity": {
    "name": "astra-test-integration-identity",
    "type": "UserAssigned"
  }
}
EOF

    log_success "Integration test data created"
}

# Create e2e test data
create_e2e_test_data() {
    log_info "Creating e2e test data..."
    
    # Sample application deployment for e2e testing
    cat > tests/data/e2e/sample-app-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-test-app
  labels:
    app: sample-test-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-test-app
  template:
    metadata:
      labels:
        app: sample-test-app
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: sample-test-app-service
spec:
  selector:
    app: sample-test-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
EOF

    # E2E test scenarios configuration
    cat > tests/data/e2e/test-scenarios.json << 'EOF'
{
  "scenarios": [
    {
      "name": "basic-platform-deployment",
      "description": "Deploy basic platform components and validate",
      "timeout": 1800,
      "steps": [
        "deploy-platform-claim",
        "wait-for-resources",
        "validate-connectivity",
        "cleanup-resources"
      ],
      "environment": "dev",
      "resources": [
        "resourcegroup",
        "containerregistry", 
        "keyvault",
        "storage",
        "managedidentity"
      ]
    },
    {
      "name": "application-deployment",
      "description": "Deploy sample application and validate functionality",
      "timeout": 900,
      "steps": [
        "deploy-application",
        "wait-for-pods",
        "test-connectivity",
        "test-scaling",
        "cleanup-application"
      ],
      "dependencies": ["basic-platform-deployment"]
    },
    {
      "name": "multi-environment-test",
      "description": "Test deployment across multiple environments",
      "timeout": 3600,
      "environments": ["dev", "staging"],
      "parallel": true
    }
  ]
}
EOF

    log_success "E2E test data created"
}

# Create test configuration templates
create_test_templates() {
    log_info "Creating test configuration templates..."
    
    # Crossplane provider config template
    cat > tests/data/templates/provider-config.yaml << 'EOF'
apiVersion: azure.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: azure-provider-config
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: azure-secret
      key: creds
  subscriptionID: "${AZURE_SUBSCRIPTION_ID}"
  tenantID: "${AZURE_TENANT_ID}"
EOF

    # Test environment kubeconfig template
    cat > tests/data/templates/kubeconfig-template.yaml << 'EOF'
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://127.0.0.1:${KUBE_PORT}
    insecure-skip-tls-verify: true
  name: test-cluster
contexts:
- context:
    cluster: test-cluster
    user: test-user
  name: test-context
current-context: test-context
users:
- name: test-user
  user:
    token: ${KUBE_TOKEN}
EOF

    log_success "Test templates created"
}

# Create performance baseline data
create_performance_data() {
    log_info "Creating performance baseline data..."
    
    cat > tests/data/performance-baseline.json << 'EOF'
{
  "platform": {
    "deployment_time": {
      "dev": 300,
      "staging": 450,
      "prod": 600
    },
    "resource_creation": {
      "resourcegroup": 30,
      "containerregistry": 120,
      "keyvault": 90,
      "storage": 60,
      "managedidentity": 45,
      "containerapp": 180
    }
  },
  "application": {
    "pod_startup_time": 30,
    "service_response_time": 100,
    "scaling_time": 120
  },
  "thresholds": {
    "cpu_usage": 80,
    "memory_usage": 80,
    "disk_usage": 85,
    "network_latency": 200
  }
}
EOF

    log_success "Performance baseline data created"
}

# Create sample test fixtures
create_test_fixtures() {
    log_info "Creating test fixtures..."
    
    # Create a sample secret for testing
    cat > tests/data/fixtures/test-secret.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: test-azure-secret
  namespace: crossplane-system
type: Opaque
data:
  creds: ewogICJjbGllbnRJZCI6ICJ0ZXN0LWNsaWVudC1pZCIsCiAgImNsaWVudFNlY3JldCI6ICJ0ZXN0LWNsaWVudC1zZWNyZXQiLAogICJzdWJzY3JpcHRpb25JZCI6ICJ0ZXN0LXN1YnNjcmlwdGlvbi1pZCIsCiAgInRlbmFudElkIjogInRlc3QtdGVuYW50LWlkIgp9
EOF

    # Create test namespace
    cat > tests/data/fixtures/test-namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: astra-test
  labels:
    purpose: testing
    environment: test
EOF

    log_success "Test fixtures created"
}

# Main function
main() {
    log_info "Setting up test data for Astra Platform..."
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Create all test data
    create_test_directories
    create_unit_test_data
    create_integration_test_data
    create_e2e_test_data
    create_test_templates
    create_performance_data
    create_test_fixtures
    
    log_success "Test data setup completed successfully!"
    log_info "Test data location: $PROJECT_ROOT/tests/data"
    log_info "Available test data:"
    echo "  - Unit test data: tests/data/unit/"
    echo "  - Integration test data: tests/data/integration/"
    echo "  - E2E test data: tests/data/e2e/"
    echo "  - Test templates: tests/data/templates/"
    echo "  - Test fixtures: tests/data/fixtures/"
    echo "  - Performance baselines: tests/data/performance-baseline.json"
}

# Run main function
main "$@"