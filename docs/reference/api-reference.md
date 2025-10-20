# API Reference Documentation

This document provides comprehensive API reference for all Custom Resource Definitions (CRDs) in the Astra Platform.

## 📚 Table of Contents

- [Platform API](#platform-api)
- [Component APIs](#component-apis)
  - [Container App API](#container-app-api)
  - [Container Registry API](#container-registry-api)
  - [Key Vault API](#key-vault-api)
  - [Managed Identity API](#managed-identity-api)
  - [Resource Group API](#resource-group-api)
  - [Storage Account API](#storage-account-api)
- [Common Types](#common-types)
- [Examples](#examples)
- [Status Conditions](#status-conditions)

## 🏗️ Platform API

### XPlatform (astra.platform/v1alpha1)

The main platform resource that orchestrates all Azure components.

#### Spec

```yaml
apiVersion: astra.platform/v1alpha1
kind: XPlatform
metadata:
  name: astra-dev-platform
spec:
  # Required: Environment configuration
  environment: "dev"  # dev, staging, prod, qa
  
  # Required: Azure region
  location: "Central India"
  
  # Optional: Naming prefix (defaults to environment)
  namingPrefix: "astra"
  
  # Optional: Resource tags
  tags:
    Environment: "dev"
    Project: "astra-platform"
    Owner: "platform-team"
    CostCenter: "engineering"
    
  # Optional: Network configuration
  networking:
    # Enable virtual network
    enableVNet: true
    # Virtual network address space
    vnetAddressSpace: "10.0.0.0/16"
    # Subnet configuration
    subnetAddressSpace: "10.0.1.0/24"
    
  # Optional: Security configuration
  security:
    # Enable managed identity
    enableManagedIdentity: true
    # Enable Key Vault
    enableKeyVault: true
    # Key Vault access policies
    keyVaultAccessPolicies:
      - tenantId: "your-tenant-id"
        objectId: "your-object-id"
        permissions:
          keys: ["get", "list", "create"]
          secrets: ["get", "list", "set"]
          certificates: ["get", "list", "create"]
  
  # Optional: Storage configuration
  storage:
    # Enable storage account
    enableStorage: true
    # Storage account type
    accountType: "Standard_LRS"
    # Enable blob public access
    allowBlobPublicAccess: false
    
  # Optional: Container registry configuration
  containerRegistry:
    # Enable container registry
    enableRegistry: true
    # Registry SKU
    sku: "Basic"
    # Enable admin user
    adminUserEnabled: false
    
  # Required: Container app configuration
  containerApp:
    # Container image
    image: "your-registry.azurecr.io/your-app:latest"
    # Resource allocation
    cpu: 0.25
    memory: "0.5Gi"
    # Scaling configuration
    minReplicas: 1
    maxReplicas: 10
    # Environment variables
    environmentVariables:
      - name: "NODE_ENV"
        value: "production"
      - name: "PORT"
        value: "3000"
    # Ingress configuration
    ingress:
      external: true
      targetPort: 3000
      allowInsecure: false
```

#### Status

```yaml
status:
  # Overall platform condition
  conditions:
    - type: "Ready"
      status: "True"
      lastTransitionTime: "2024-01-15T10:30:00Z"
      reason: "AllComponentsReady"
      message: "All platform components are ready"
      
  # Component statuses
  components:
    resourceGroup:
      ready: true
      resourceId: "/subscriptions/{id}/resourceGroups/astra-dev-rg"
    managedIdentity:
      ready: true
      resourceId: "/subscriptions/{id}/resourceGroups/astra-dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/astra-dev-identity"
      clientId: "client-id-here"
      principalId: "principal-id-here"
    keyVault:
      ready: true
      resourceId: "/subscriptions/{id}/resourceGroups/astra-dev-rg/providers/Microsoft.KeyVault/vaults/astra-dev-kv"
      vaultUri: "https://astra-dev-kv.vault.azure.net/"
    storage:
      ready: true
      resourceId: "/subscriptions/{id}/resourceGroups/astra-dev-rg/providers/Microsoft.Storage/storageAccounts/astradevst"
      primaryEndpoint: "https://astradevst.blob.core.windows.net/"
    containerRegistry:
      ready: true
      resourceId: "/subscriptions/{id}/resourceGroups/astra-dev-rg/providers/Microsoft.ContainerRegistry/registries/astradevacr"
      loginServer: "astradevacr.azurecr.io"
    containerApp:
      ready: true
      resourceId: "/subscriptions/{id}/resourceGroups/astra-dev-rg/providers/Microsoft.App/containerApps/astra-dev-app"
      applicationUrl: "https://astra-dev-app.happywater-12345.centralindia.azurecontainerapps.io"
      
  # Platform-wide information
  platformInfo:
    resourceGroupName: "astra-dev-rg"
    location: "Central India"
    subscriptionId: "subscription-id-here"
    managedIdentityClientId: "client-id-here"
    
  # Last update timestamp
  lastUpdated: "2024-01-15T10:30:00Z"
```

## 🧩 Component APIs

### Container App API

#### XContainerApp (astra.platform/v1alpha1)

```yaml
apiVersion: astra.platform/v1alpha1
kind: XContainerApp
metadata:
  name: example-container-app
spec:
  # Required: Basic configuration
  namingPrefix: "astra"
  environment: "dev"
  location: "Central India"
  
  # Required: Container configuration
  containerImage: "nginx:latest"
  cpu: 0.25
  memory: "0.5Gi"
  
  # Optional: Scaling configuration
  minReplicas: 1
  maxReplicas: 10
  
  # Optional: Environment variables
  environmentVariables:
    - name: "VAR_NAME"
      value: "value"
    - name: "SECRET_VAR"
      secretRef: "secret-name"
      
  # Optional: Ingress configuration
  ingress:
    external: true
    targetPort: 80
    allowInsecure: false
    
  # Optional: Resource dependencies
  dependencies:
    resourceGroupName: "astra-dev-rg"
    containerRegistryName: "astradevacr"
    managedIdentityId: "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{name}"
```

### Container Registry API

#### XContainerRegistry (astra.platform/v1alpha1)

```yaml
apiVersion: astra.platform/v1alpha1
kind: XContainerRegistry
metadata:
  name: example-container-registry
spec:
  # Required: Basic configuration
  namingPrefix: "astra"
  environment: "dev"
  location: "Central India"
  
  # Optional: Registry configuration
  sku: "Basic"  # Basic, Standard, Premium
  adminUserEnabled: false
  
  # Optional: Network access
  networkRuleSet:
    defaultAction: "Allow"  # Allow, Deny
    
  # Optional: Resource dependencies
  dependencies:
    resourceGroupName: "astra-dev-rg"
```

### Key Vault API

#### XKeyVault (astra.platform/v1alpha1)

```yaml
apiVersion: astra.platform/v1alpha1
kind: XKeyVault
metadata:
  name: example-key-vault
spec:
  # Required: Basic configuration
  namingPrefix: "astra"
  environment: "dev"
  location: "Central India"
  
  # Required: Tenant ID
  tenantId: "your-tenant-id"
  
  # Optional: SKU configuration
  sku: "standard"  # standard, premium
  
  # Optional: Access policies
  accessPolicies:
    - tenantId: "your-tenant-id"
      objectId: "user-or-service-principal-id"
      permissions:
        keys: ["get", "list", "create", "delete"]
        secrets: ["get", "list", "set", "delete"]
        certificates: ["get", "list", "create", "delete"]
        
  # Optional: Network access
  networkAcls:
    defaultAction: "Allow"  # Allow, Deny
    bypass: "AzureServices"
    
  # Optional: Resource dependencies
  dependencies:
    resourceGroupName: "astra-dev-rg"
```

### Managed Identity API

#### XManagedIdentity (astra.platform/v1alpha1)

```yaml
apiVersion: astra.platform/v1alpha1
kind: XManagedIdentity
metadata:
  name: example-managed-identity
spec:
  # Required: Basic configuration
  namingPrefix: "astra"
  environment: "dev"
  location: "Central India"
  
  # Optional: Identity type
  type: "UserAssigned"  # UserAssigned (only supported type)
  
  # Optional: Resource dependencies
  dependencies:
    resourceGroupName: "astra-dev-rg"
```

### Resource Group API

#### XResourceGroup (astra.platform/v1alpha1)

```yaml
apiVersion: astra.platform/v1alpha1
kind: XResourceGroup
metadata:
  name: example-resource-group
spec:
  # Required: Basic configuration
  namingPrefix: "astra"
  environment: "dev"
  location: "Central India"
  
  # Optional: Tags
  tags:
    Environment: "dev"
    Project: "astra-platform"
    Owner: "platform-team"
```

### Storage Account API

#### XStorageAccount (astra.platform/v1alpha1)

```yaml
apiVersion: astra.platform/v1alpha1
kind: XStorageAccount
metadata:
  name: example-storage-account
spec:
  # Required: Basic configuration
  namingPrefix: "astra"
  environment: "dev"
  location: "Central India"
  
  # Optional: Storage configuration
  accountType: "Standard_LRS"  # Standard_LRS, Standard_GRS, Premium_LRS
  allowBlobPublicAccess: false
  
  # Optional: Network access
  networkRuleSet:
    defaultAction: "Allow"  # Allow, Deny
    bypass: "AzureServices"
    
  # Optional: Resource dependencies
  dependencies:
    resourceGroupName: "astra-dev-rg"
```

## 🔧 Common Types

### Environment Type

```yaml
# Valid environment values
environment: "dev" | "staging" | "prod" | "qa"
```

### Location Type

```yaml
# Azure regions (examples)
location: "Central India" | "East US" | "West Europe" | "Southeast Asia"
```

### Tags Type

```yaml
tags:
  key1: "value1"
  key2: "value2"
  # Common tags
  Environment: "dev"
  Project: "astra-platform"
  Owner: "team-name"
  CostCenter: "department"
```

### Resource Dependencies

```yaml
dependencies:
  resourceGroupName: "string"
  managedIdentityId: "string"
  keyVaultName: "string"
  storageAccountName: "string"
  containerRegistryName: "string"
```

## 📋 Examples

### Complete Platform Example

```yaml
apiVersion: astra.platform/v1alpha1
kind: XPlatform
metadata:
  name: my-app-platform
  namespace: default
spec:
  environment: "dev"
  location: "Central India"
  namingPrefix: "myapp"
  
  tags:
    Environment: "dev"
    Project: "my-application"
    Owner: "development-team"
    
  networking:
    enableVNet: true
    vnetAddressSpace: "10.0.0.0/16"
    subnetAddressSpace: "10.0.1.0/24"
    
  security:
    enableManagedIdentity: true
    enableKeyVault: true
    
  storage:
    enableStorage: true
    accountType: "Standard_LRS"
    
  containerRegistry:
    enableRegistry: true
    sku: "Basic"
    
  containerApp:
    image: "myapp-acr.azurecr.io/myapp:v1.0.0"
    cpu: 0.5
    memory: "1Gi"
    minReplicas: 2
    maxReplicas: 10
    environmentVariables:
      - name: "NODE_ENV"
        value: "production"
      - name: "DB_CONNECTION_STRING"
        secretRef: "database-secret"
    ingress:
      external: true
      targetPort: 3000
      allowInsecure: false
```

### Container App Only Example

```yaml
apiVersion: astra.platform/v1alpha1
kind: XContainerApp
metadata:
  name: simple-app
spec:
  namingPrefix: "simple"
  environment: "dev"
  location: "Central India"
  containerImage: "nginx:latest"
  cpu: 0.25
  memory: "0.5Gi"
  ingress:
    external: true
    targetPort: 80
  dependencies:
    resourceGroupName: "existing-rg"
    managedIdentityId: "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{name}"
```

## 📊 Status Conditions

### Condition Types

```yaml
conditions:
  - type: "Ready"
    status: "True" | "False" | "Unknown"
    lastTransitionTime: "2024-01-15T10:30:00Z"
    reason: "string"
    message: "string"
    
  - type: "Synced"
    status: "True" | "False" | "Unknown"
    lastTransitionTime: "2024-01-15T10:30:00Z"
    reason: "string"
    message: "string"
```

### Common Condition Reasons

#### Ready Conditions
- `AllComponentsReady`: All components are ready
- `ComponentNotReady`: One or more components not ready
- `DependencyMissing`: Required dependency missing
- `ConfigurationError`: Invalid configuration

#### Synced Conditions
- `ReconcileSuccess`: Resource successfully reconciled
- `ReconcileError`: Error during reconciliation
- `DependencyNotFound`: Required dependency not found
- `ProviderError`: Azure provider error

### Status Examples

#### Successful Deployment
```yaml
status:
  conditions:
    - type: "Ready"
      status: "True"
      lastTransitionTime: "2024-01-15T10:30:00Z"
      reason: "AllComponentsReady"
      message: "All platform components are ready and available"
    - type: "Synced"
      status: "True"
      lastTransitionTime: "2024-01-15T10:30:00Z"
      reason: "ReconcileSuccess"
      message: "Resource successfully reconciled"
```

#### Failed Deployment
```yaml
status:
  conditions:
    - type: "Ready"
      status: "False"
      lastTransitionTime: "2024-01-15T10:30:00Z"
      reason: "ComponentNotReady"
      message: "Container App deployment failed: image pull error"
    - type: "Synced"
      status: "False"
      lastTransitionTime: "2024-01-15T10:30:00Z"
      reason: "ReconcileError"
      message: "Failed to create Azure resources: authorization error"
```

## 🔍 Field Validation

### Required Fields
- `namingPrefix`: Must be 3-10 characters, alphanumeric only
- `environment`: Must be one of "dev", "staging", "prod", "qa"
- `location`: Must be valid Azure region

### Optional Field Defaults
- `cpu`: Defaults to 0.25
- `memory`: Defaults to "0.5Gi"
- `minReplicas`: Defaults to 1
- `maxReplicas`: Defaults to 10
- `accountType`: Defaults to "Standard_LRS"
- `sku`: Defaults to "Basic"

### Field Constraints
- `namingPrefix`: 3-10 characters, lowercase alphanumeric
- `cpu`: 0.25-4.0 in 0.25 increments
- `memory`: 0.5Gi-8Gi in 0.5Gi increments
- `minReplicas`: 0-1000
- `maxReplicas`: 1-1000 (must be >= minReplicas)

## 📚 Additional Resources

- [Crossplane Composition Reference](https://crossplane.io/docs/latest/concepts/compositions/)
- [Azure Provider Documentation](https://marketplace.upbound.io/providers/upbound/provider-azure/)
- [Kubernetes API Conventions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)
- [Custom Resource Definition Documentation](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)