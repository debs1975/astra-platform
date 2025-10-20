# Platform Architecture

The Astra Platform is built on Crossplane to provide a declarative, Kubernetes-native approach to managing Azure infrastructure and Container Apps deployment.

## 🏗️ High-Level Architecture

```mermaid
graph TB
    subgraph "Local Development Environment"
        K8s[Kubernetes Cluster<br/>Minikube/Docker Desktop]
        CP[Crossplane Control Plane]
        XRD[XRDs & Compositions]
        Claims[Platform Claims]
    end
    
    subgraph "Azure Cloud"
        subgraph "Dev Environment - astra-dev-*"
            RG1[Resource Group]
            MI1[Managed Identity]
            KV1[Key Vault]
            ACR1[Container Registry]
            SA1[Storage Account]
            CAE1[Container App Environment]
            CA1[Container App]
        end
        
        subgraph "Staging Environment - astra-staging-*"
            RG2[Resource Group]
            MI2[Managed Identity]
            KV2[Key Vault]
            ACR2[Container Registry]
            SA2[Storage Account]
            CAE2[Container App Environment]
            CA2[Container App]
        end
        
        subgraph "Production Environment - astra-prod-*"
            RG3[Resource Group]
            MI3[Managed Identity]
            KV3[Key Vault]
            ACR3[Container Registry]
            SA3[Storage Account]
            CAE3[Container App Environment]
            CA3[Container App]
        end
    end
    
    CP --> XRD
    XRD --> Claims
    Claims --> RG1
    Claims --> RG2
    Claims --> RG3
    
    RG1 --> MI1 --> KV1
    RG1 --> ACR1 --> SA1
    RG1 --> CAE1 --> CA1
    
    RG2 --> MI2 --> KV2
    RG2 --> ACR2 --> SA2
    RG2 --> CAE2 --> CA2
    
    RG3 --> MI3 --> KV3
    RG3 --> ACR3 --> SA3
    RG3 --> CAE3 --> CA3
```

## 🔧 Core Components

### 1. Crossplane Control Plane
- **Purpose**: Kubernetes-native infrastructure management
- **Version**: 1.14.0
- **Provider**: Azure Provider v0.36.0
- **Deployment**: Runs locally in Minikube or Docker Desktop

### 2. Custom Resource Definitions (XRDs)
Seven XRDs define the platform's API surface:

| XRD | Purpose | Azure Resources |
|-----|---------|-----------------|
| `XResourceGroup` | Resource container | Resource Group |
| `XManagedIdentity` | Authentication | User Assigned Managed Identity |
| `XKeyVault` | Secrets management | Key Vault + Access Policies |
| `XContainerRegistry` | Image storage | Azure Container Registry |
| `XStorage` | Data persistence | Storage Account + Blob Container |
| `XContainerApp` | Application runtime | Container App + Environment |
| `XPlatform` | Orchestrator | All above resources |

### 3. Compositions
Compositions implement the XRDs using Azure Provider resources:

```yaml
XPlatform (Orchestrator)
├── XResourceGroup → azurerm_resource_group
├── XManagedIdentity → azurerm_user_assigned_identity
├── XKeyVault → azurerm_key_vault + access_policy
├── XContainerRegistry → azurerm_container_registry
├── XStorage → azurerm_storage_account + container
└── XContainerApp → azurerm_container_app + environment
```

## 📋 Resource Hierarchy

### Platform-Level Orchestration
```yaml
XPlatform Claim
├── Dependencies Flow:
│   1. Resource Group (foundation)
│   2. Managed Identity (authentication)
│   3. Key Vault (secrets, depends on MI)
│   4. Container Registry (images, depends on MI)
│   5. Storage Account (data, depends on MI)
│   6. Container App (runtime, depends on all above)
```

### Field Propagation
```yaml
Platform Claim Input:
├── namingPrefix: "astra-dev"
├── location: "Central India"
├── tenantId: "xxx-xxx-xxx"
├── containerImage: "app:latest"
└── scaling parameters

Automatic Field Mapping:
├── Resource Group: "${namingPrefix}-rg"
├── Managed Identity: "${namingPrefix}-mi"
├── Key Vault: "${namingPrefix}-kv"
├── Container Registry: "${namingPrefix}acr" (no hyphens)
├── Storage Account: "${namingPrefix}sa" (no hyphens)
└── Container App: "${namingPrefix}-app"
```

## 🔐 Security Architecture

### 1. Azure RBAC Integration
```mermaid
graph TB
    subgraph "Authentication Layer"
        SP[Service Principal<br/>Crossplane Auth]
        AAD[Azure Active Directory]
    end
    
    subgraph "Crossplane Control Plane"
        CP[Crossplane]
        Provider[Azure Provider]
    end
    
    subgraph "Created Resources"
        MI[Managed Identity<br/>App Authentication]
    end
    
    subgraph "RBAC Assignments"
        direction TB
        R1[Contributor Role<br/>Subscription Level]
        R2[AcrPull Role<br/>Container Registry]
        R3[Key Vault Secrets User<br/>Key Vault]
        R4[Storage Blob Data Contributor<br/>Storage Account]
    end
    
    subgraph "Azure Services"
        ACR[Container Registry]
        KV[Key Vault]
        SA[Storage Account]
        CA[Container App]
    end
    
    SP --> AAD
    AAD --> CP
    CP --> Provider
    Provider --> MI
    
    SP -.Assigned.-> R1
    MI -.Assigned.-> R2
    MI -.Assigned.-> R3
    MI -.Assigned.-> R4
    
    R2 --> ACR
    R3 --> KV
    R4 --> SA
    
    MI -.Uses.-> CA
    CA -.Pulls Images.-> ACR
    CA -.Reads Secrets.-> KV
    CA -.Access Data.-> SA
    
    style SP fill:#FFB900,color:#000
    style MI fill:#FFB900,color:#000
    style CP fill:#326CE5,color:#fff
    style CA fill:#8661C5,color:#fff
```

### 2. Identity and Access Flow
```mermaid
sequenceDiagram
    participant CP as Crossplane
    participant Azure as Azure ARM
    participant MI as Managed Identity
    participant ACR as Container Registry
    participant KV as Key Vault
    participant SA as Storage Account
    participant CA as Container App
    
    Note over CP,CA: Resource Creation Phase
    CP->>Azure: Create Managed Identity
    Azure-->>CP: MI Created (Principal ID: xxx)
    
    CP->>Azure: Create Container Registry
    Azure-->>CP: ACR Created
    
    CP->>Azure: Assign AcrPull Role<br/>(MI → ACR)
    Azure-->>CP: Role Assignment Complete
    
    CP->>Azure: Create Key Vault
    Azure-->>CP: KV Created
    
    CP->>Azure: Assign Key Vault Secrets User<br/>(MI → KV)
    Azure-->>CP: Role Assignment Complete
    
    CP->>Azure: Create Storage Account
    Azure-->>CP: SA Created
    
    CP->>Azure: Assign Storage Blob Contributor<br/>(MI → SA)
    Azure-->>CP: Role Assignment Complete
    
    Note over CP,CA: Application Runtime Phase
    CP->>Azure: Create Container App with MI
    Azure-->>CP: CA Created
    
    CA->>MI: Request Token
    MI-->>CA: Access Token
    
    CA->>ACR: Pull Image (with token)
    ACR-->>CA: Image Downloaded
    
    CA->>KV: Get Secret (with token)
    KV-->>CA: Secret Value
    
    CA->>SA: Access Blob (with token)
    SA-->>CA: Blob Data
    
    CA-->>CP: Application Running
```

### 2. Network Security
- **Container Apps**: Public ingress with HTTPS termination
- **Key Vault**: Network access policies (configurable)
- **Storage**: Private blob access via Managed Identity
- **Container Registry**: Token-based authentication

```mermaid
graph LR
    subgraph "Public Internet"
        User[Users]
        HTTPS[HTTPS Traffic]
    end
    
    subgraph "Azure Container Apps"
        Ingress[Ingress Controller<br/>HTTPS/443]
        CA[Container App<br/>Instances]
    end
    
    subgraph "Private Communication"
        MI[Managed Identity<br/>Token-based Auth]
    end
    
    subgraph "Azure Services - Private Access"
        ACR[Container Registry<br/>Token Auth]
        KV[Key Vault<br/>RBAC Access]
        SA[Storage Account<br/>Private Access]
    end
    
    User --> HTTPS
    HTTPS --> Ingress
    Ingress --> CA
    
    CA --> MI
    MI -.Token.-> ACR
    MI -.Token.-> KV
    MI -.Token.-> SA
    
    style Ingress fill:#0078D4,color:#fff
    style MI fill:#FFB900,color:#000
    style CA fill:#8661C5,color:#fff
```

### 3. Secrets Management
```yaml
Secret Flow:
1. Azure Service Principal → Kubernetes Secret
2. ProviderConfig → References K8s Secret
3. Managed Identity → Created by Crossplane
4. Container App → Uses Managed Identity
5. Key Vault → Accessible via Managed Identity
```

## 🌍 Multi-Environment Strategy

### Environment Isolation
Each environment gets its own:
- Azure Resource Group
- Managed Identity with scoped permissions
- Complete resource stack
- Kubernetes namespace

### Environment Configurations
| Environment | Namespace | Replicas | Resources | Purpose |
|-------------|-----------|----------|-----------|---------|
| **dev** | `astra-dev` | 1-3 | 0.25 CPU, 0.5Gi | Development/Testing |
| **staging** | `astra-staging` | 2-5 | 0.5 CPU, 1Gi | Pre-production validation |
| **prod** | `astra-prod` | 3-10 | 1.0 CPU, 2Gi | Production workloads |

### Kustomize Overlays
```yaml
Base Configuration (packages/platform/):
├── XRD definitions
├── Compositions
└── Default platform claim

Environment Overlays (overlays/{env}/):
├── Environment-specific values
├── Resource scaling
├── Configuration overrides
└── Namespace targeting
```

## 🔄 Deployment Flow

### 1. Platform Claim Lifecycle
```mermaid
sequenceDiagram
    participant User
    participant K8s
    participant Crossplane
    participant Azure
    
    User->>K8s: kubectl apply -k overlays/dev
    K8s->>Crossplane: Platform Claim Created
    Crossplane->>Crossplane: Validate Claim
    Crossplane->>Azure: Create Resource Group
    Azure-->>Crossplane: RG Created
    Crossplane->>Azure: Create Managed Identity
    Azure-->>Crossplane: MI Created
    Crossplane->>Azure: Create Key Vault
    Azure-->>Crossplane: KV Created
    Crossplane->>Azure: Create Container Registry
    Azure-->>Crossplane: ACR Created
    Crossplane->>Azure: Create Storage Account
    Azure-->>Crossplane: SA Created
    Crossplane->>Azure: Create Container App
    Azure-->>Crossplane: App Ready
    Crossplane->>K8s: Update Claim Status
    K8s-->>User: Platform Ready
```

### 2. Resource Dependencies
```yaml
Dependency Chain:
1. Resource Group (no dependencies)
2. Managed Identity → Resource Group
3. Key Vault → Resource Group + Managed Identity
4. Container Registry → Resource Group + Managed Identity
5. Storage Account → Resource Group + Managed Identity
6. Container App → Resource Group + All above resources
```

```mermaid
graph TD
    subgraph "Dependency Levels"
        Level0[Level 0: Foundation]
        Level1[Level 1: Identity]
        Level2[Level 2: Supporting Services]
        Level3[Level 3: Application Runtime]
    end
    
    subgraph "Level 0: Foundation"
        RG[Resource Group<br/>No Dependencies]
    end
    
    subgraph "Level 1: Identity"
        MI[Managed Identity<br/>Depends on: RG]
    end
    
    subgraph "Level 2: Supporting Services"
        KV[Key Vault<br/>Depends on: RG, MI]
        ACR[Container Registry<br/>Depends on: RG, MI]
        SA[Storage Account<br/>Depends on: RG, MI]
        LAW[Log Analytics<br/>Depends on: RG]
    end
    
    subgraph "Level 3: Application Runtime"
        CAE[Container Apps Environment<br/>Depends on: RG, LAW]
        CA[Container App<br/>Depends on: All Above]
    end
    
    RG --> MI
    RG --> LAW
    
    RG --> KV
    MI --> KV
    
    RG --> ACR
    MI --> ACR
    
    RG --> SA
    MI --> SA
    
    RG --> CAE
    LAW --> CAE
    
    RG --> CA
    MI --> CA
    KV --> CA
    ACR --> CA
    SA --> CA
    CAE --> CA
    
    style RG fill:#7FBA00,color:#fff
    style MI fill:#FFB900,color:#000
    style CA fill:#8661C5,color:#fff
    
    classDef level0 fill:#7FBA00,color:#fff
    classDef level1 fill:#FFB900,color:#000
    classDef level2 fill:#0078D4,color:#fff
    classDef level3 fill:#8661C5,color:#fff
    
    class RG level0
    class MI level1
    class KV,ACR,SA,LAW level2
    class CAE,CA level3
```

## � Crossplane Reconciliation Loop

```mermaid
stateDiagram-v2
    [*] --> Observe: Platform Claim Created
    Observe --> Compare: Read Desired State
    Compare --> Diff: Read Actual State
    Diff --> NoDifference: States Match
    Diff --> HasDifference: States Differ
    
    NoDifference --> Observe: Continue Monitoring
    
    HasDifference --> CreateResources: Resources Missing
    HasDifference --> UpdateResources: Resources Outdated
    HasDifference --> DeleteResources: Resources Extra
    
    CreateResources --> ApplyChanges: Create in Azure
    UpdateResources --> ApplyChanges: Update in Azure
    DeleteResources --> ApplyChanges: Delete from Azure
    
    ApplyChanges --> WaitForReady: Azure Processing
    WaitForReady --> UpdateStatus: Resources Ready
    UpdateStatus --> Observe: Status Updated
    
    WaitForReady --> Error: Failure
    Error --> Retry: Backoff
    Retry --> Observe: Retry Reconcile
    
    note right of Observe
        Crossplane continuously
        monitors Platform Claims
        every 60 seconds
    end note
    
    note right of ApplyChanges
        Crossplane uses Azure
        Provider to make changes
        via Azure ARM API
    end note
```

## �📊 Monitoring & Observability

### 1. Crossplane Observability
```yaml
Monitoring Points:
├── XRD Status: kubectl get xrd
├── Composition Health: kubectl get compositions
├── Claim Status: kubectl get xplatform -n {namespace}
├── Managed Resources: kubectl get managedresources
└── Provider Logs: kubectl logs -n crossplane-system
```

### 2. Resource Status Propagation

```mermaid
graph TD
    subgraph "Azure Cloud"
        AzureRG[Azure Resource Group<br/>Status: Succeeded]
        AzureMI[Azure Managed Identity<br/>Status: Succeeded]
        AzureKV[Azure Key Vault<br/>Status: Active]
        AzureCA[Azure Container App<br/>Status: Running]
    end
    
    subgraph "Crossplane Managed Resources"
        MRG[ResourceGroup<br/>Status: Ready]
        MMI[UserAssignedIdentity<br/>Status: Ready]
        MKV[Vault<br/>Status: Ready]
        MCA[ContainerApp<br/>Status: Ready]
    end
    
    subgraph "Composite Resources"
        XRG[XResourceGroup<br/>Status: Ready]
        XMI[XManagedIdentity<br/>Status: Ready]
        XKV[XKeyVault<br/>Status: Ready]
        XCA[XContainerApp<br/>Status: Ready]
    end
    
    subgraph "Platform Claim"
        Platform[XPlatform<br/>Status: Ready<br/>applicationUrl: https://...]
    end
    
    AzureRG -.Status Sync.-> MRG
    AzureMI -.Status Sync.-> MMI
    AzureKV -.Status Sync.-> MKV
    AzureCA -.Status Sync.-> MCA
    
    MRG --> XRG
    MMI --> XMI
    MKV --> XKV
    MCA --> XCA
    
    XRG --> Platform
    XMI --> Platform
    XKV --> Platform
    XCA --> Platform
    
    style Platform fill:#8661C5,color:#fff
    style AzureCA fill:#0078D4,color:#fff
```

### 2. Azure Resource Monitoring
```yaml
Azure Monitoring:
├── Resource Groups: az group list
├── Container Apps: az containerapp list
├── Application Insights: Built-in monitoring
├── Log Analytics: Centralized logging
└── Azure Monitor: Metrics and alerts
```

### 3. Status Propagation
```yaml
Status Flow:
Azure Resource Status → Managed Resource → Composition → XRD → Platform Claim

Platform Claim Status Fields:
├── .status.ready: Overall readiness
├── .status.applicationUrl: Container App FQDN
├── .status.resourceGroupName: Created RG name
├── .status.managedIdentityId: Identity resource ID
└── .status.{service}Name: Individual resource names
```

## 🔧 Extensibility

### 1. Adding New Azure Services
```yaml
Extension Pattern:
1. Create new XRD definition
2. Create corresponding Composition
3. Add to Platform Composition as dependency
4. Update environment overlays
5. Test in dev environment
```

### 2. Custom Configurations
```yaml
Customization Points:
├── Resource naming patterns
├── Azure regions and availability zones
├── Container App scaling policies
├── Network security configurations
├── Backup and retention policies
└── Monitoring and alerting rules
```

## 🚀 Performance Characteristics

### 1. Deployment Times
- **Initial Platform**: 8-12 minutes
- **Application Update**: 2-3 minutes
- **Scaling Events**: 30-60 seconds
- **Environment Teardown**: 5-8 minutes

### 2. Resource Limits
- **Max Environments**: Limited by Azure subscription quotas
- **Container Apps**: 10 replicas max per environment (configurable)
- **Concurrent Deployments**: 3 environments simultaneously
- **Resource Groups**: 980 per subscription (Azure limit)

### 3. Cost Optimization
- **Development**: ~$10-20/month per environment
- **Production**: ~$50-100/month per environment
- **Auto-scaling**: Scales to zero when no traffic
- **Shared Resources**: Container Registry shared across environments

## 🔮 Future Enhancements

### Planned Features
- [ ] Multi-region deployment support
- [ ] Database integration (PostgreSQL, Redis)
- [ ] Service mesh integration (Istio)
- [ ] GitOps workflow (ArgoCD)
- [ ] Advanced networking (VNet integration)
- [ ] Disaster recovery automation

### Architecture Evolution
- Support for Azure Kubernetes Service (AKS)
- Integration with Azure Arc
- Multi-cloud support (AWS, GCP)
- Advanced RBAC with Azure AD groups