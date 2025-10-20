# Astra Platform - Mermaid Diagrams Index

This document provides an index of all Mermaid diagrams added throughout the Astra Platform documentation to help visualize application and infrastructure setup.

## 📋 Table of Contents

1. [Architecture Diagrams](#architecture-diagrams)
2. [Deployment Flow Diagrams](#deployment-flow-diagrams)
3. [Security & RBAC Diagrams](#security--rbac-diagrams)
4. [CI/CD Pipeline Diagrams](#cicd-pipeline-diagrams)
5. [Application Runtime Diagrams](#application-runtime-diagrams)

---

## Architecture Diagrams

### Platform Architecture Overview
**Location**: `docs/architecture/platform-architecture.md`

- **High-Level Architecture**: Shows the complete platform structure with Crossplane control plane, Azure environments (dev/staging/prod), and resource organization
- **Core Components**: Illustrates the relationship between XRDs, Compositions, and Azure resources
- **Resource Hierarchy**: Displays the orchestration flow from XPlatform to individual Azure services

### Multi-Environment Architecture
**Location**: `docs/user-guides/platform-deployment.md`

- **Multi-Environment Setup**: Visualizes how different environments (dev/staging/prod) are isolated with separate resource groups and namespaces
- **Environment Isolation**: Shows Kubernetes namespace separation and corresponding Azure resource groups

---

## Deployment Flow Diagrams

### Initial Setup Journey
**Location**: `docs/getting-started/initial-setup.md`

- **Setup Journey Map**: Interactive flowchart showing the complete setup process from prerequisites to deployment
- **Platform Components Installation**: Illustrates the installation order of Crossplane, Azure Provider, XRDs, and Compositions
- **Decision Points**: Highlights critical decision points like cluster selection and environment configuration

### Platform Deployment Flow
**Location**: `docs/user-guides/platform-deployment.md`

- **Deployment Sequence**: Detailed sequence diagram showing the interaction between developer, kubectl, Crossplane, and Azure
- **Phase-by-Phase Deployment**: Breaks down deployment into infrastructure setup, credential configuration, platform definitions, and environment deployment
- **Resource Creation Timeline**: Shows the order and dependencies of Azure resource creation

### Application Deployment Workflow
**Location**: `docs/user-guides/application-deployment.md`

- **Complete Deployment Pipeline**: Shows the journey from application code to running container app
- **Deployment Lifecycle State Machine**: State diagram showing all stages of deployment including build, push, deploy, health checks, and updates
- **Integration Points**: Highlights where ACR, Key Vault, Storage, and Crossplane interact

---

## Security & RBAC Diagrams

### Azure RBAC Integration
**Location**: `docs/architecture/platform-architecture.md`

- **Authentication Layer**: Shows Service Principal and Azure AD integration with Crossplane
- **RBAC Assignments**: Visualizes role assignments including Contributor, AcrPull, Key Vault Secrets User, and Storage Blob Data Contributor
- **Identity Flow**: Sequence diagram showing how Managed Identity is created and roles are assigned

### Network Security
**Location**: `docs/architecture/platform-architecture.md`

- **Network Architecture**: Displays public internet access through HTTPS ingress and private communication between services
- **Security Boundaries**: Shows how Container Apps communicate securely with Azure services using Managed Identity

### RBAC Role Assignments (Azure CLI)
**Location**: `docs/operations/azure-resources-creation.md`

- **Role Assignment Flow**: Shows Managed Identity and its role assignments to ACR, Key Vault, and Storage Account
- **Container App Access**: Illustrates how Container App uses Managed Identity to access protected resources

---

## CI/CD Pipeline Diagrams

### Azure DevOps Pipeline Architecture
**Location**: `docs/operations/cicd-setup.md`

- **6-Stage Pipeline**: Comprehensive view of Validate → Test → Security → Build → Deploy → Release stages
- **Environment Flow**: Shows deployment progression from Dev → Staging → Production with approval gates
- **Integration Points**: Displays connections between Azure DevOps, Azure Cloud, and environments

### Pipeline Execution Flow
**Location**: `docs/operations/cicd-setup.md`

- **Detailed Sequence**: Step-by-step sequence diagram from git push to deployment complete
- **Approval Process**: Highlights manual approval requirements for staging and production
- **Parallel Execution**: Shows which stages run in parallel for optimization

---

## Application Runtime Diagrams

### Application Architecture
**Location**: `docs/user-guides/application-deployment.md`

- **Runtime Components**: Shows all components involved in running the application including Ingress, Load Balancer, Container App instances, Managed Identity, Key Vault, ACR, Storage, and Log Analytics
- **Auto-scaling**: Visualizes multiple container app instances behind load balancer
- **Service Integration**: Shows how app instances interact with Azure services

### Application Runtime Data Flow
**Location**: `docs/user-guides/application-deployment.md`

- **Startup Sequence**: Detailed sequence showing application initialization including token acquisition, image pull, secret retrieval, and storage connection
- **User Request Flow**: Complete flow from user HTTPS request through ingress, app processing, and response
- **Monitoring**: Shows how logs and metrics flow to Log Analytics

---

## Infrastructure Setup Diagrams

### Azure Resources Topology
**Location**: `docs/operations/azure-resources-creation.md`

- **Infrastructure Components**: Complete topology showing all Azure resources created by the CLI script
- **Resource Dependencies**: Visual representation of dependencies between Resource Group, Managed Identity, ACR, Key Vault, Storage, Log Analytics, Container Apps Environment, and Container App
- **Resource Naming**: Shows naming conventions for all resources

### Resource Creation Flow
**Location**: `docs/operations/azure-resources-creation.md`

- **8-Step Creation Process**: Sequence diagram showing each step of resource creation with validation
- **Azure CLI Interaction**: Displays the script's interaction with Azure ARM API
- **Role Assignment Process**: Shows when and how RBAC roles are assigned during creation

### Resource Configuration Details
**Location**: `docs/operations/azure-resources-creation.md`

- **Configuration Overview**: Detailed view of each resource with SKU, type, and configuration parameters
- **Monitoring Integration**: Shows Log Analytics connection to Container Apps Environment

---

## Crossplane-Specific Diagrams

### Crossplane Reconciliation Loop
**Location**: `docs/architecture/platform-architecture.md`

- **State Machine**: Shows the continuous reconciliation process of observing, comparing, and applying changes
- **Error Handling**: Illustrates retry logic and backoff strategy
- **Status Updates**: Shows how status propagates through the system

### Resource Status Propagation
**Location**: `docs/architecture/platform-architecture.md`

- **4-Layer Status Flow**: Shows status propagation from Azure resources → Managed Resources → Composite Resources → Platform Claim
- **Real-time Sync**: Illustrates continuous status synchronization

### Resource Dependencies
**Location**: `docs/architecture/platform-architecture.md`

- **4-Level Dependency Graph**: 
  - Level 0: Foundation (Resource Group)
  - Level 1: Identity (Managed Identity)
  - Level 2: Supporting Services (KV, ACR, Storage, Log Analytics)
  - Level 3: Application Runtime (Container Apps Environment, Container App)
- **Dependency Lines**: Shows all dependencies between resources

---

## Diagram Usage Guidelines

### Viewing Diagrams
All diagrams are written in Mermaid syntax and will render automatically in:
- GitHub markdown viewers
- GitLab markdown viewers
- VS Code with Mermaid preview extensions
- Documentation sites using Mermaid plugins

### Diagram Color Scheme
The diagrams use a consistent color scheme aligned with Azure branding:

| Color | Hex Code | Usage |
|-------|----------|-------|
| Azure Blue | `#0078D4` | Azure services, ingress |
| Kubernetes Blue | `#326CE5` | Crossplane, Kubernetes components |
| Green | `#7FBA00` | Success states, resource groups |
| Yellow/Gold | `#FFB900` | Identity, authentication |
| Purple | `#8661C5` | Container Apps, applications |
| Red | `#E74856` | Key Vault, security components |

### Editing Diagrams
To edit diagrams:
1. Locate the diagram in the markdown file
2. Edit the Mermaid code block
3. Preview using a Mermaid-compatible viewer
4. Test rendering in your target platform

### Adding New Diagrams
When adding new diagrams:
1. Follow the existing color scheme
2. Use clear, descriptive labels
3. Keep diagrams focused on one concept
4. Add diagram reference to this index
5. Include diagram title and location in documentation

---

## Diagram Statistics

| Documentation File | Number of Diagrams | Diagram Types |
|-------------------|-------------------|---------------|
| `architecture/platform-architecture.md` | 7 | Architecture, Sequence, State, Graph |
| `operations/azure-resources-creation.md` | 4 | Graph, Sequence, Architecture |
| `user-guides/application-deployment.md` | 4 | Graph, State, Sequence, Architecture |
| `user-guides/platform-deployment.md` | 2 | Sequence, Architecture |
| `getting-started/initial-setup.md` | 2 | Graph, Architecture |
| `operations/cicd-setup.md` | 2 | Graph, Sequence |
| **Total** | **21** | **Multiple Types** |

---

## Related Documentation

- [Platform Architecture](architecture/platform-architecture.md) - Complete technical architecture
- [Application Deployment Guide](user-guides/application-deployment.md) - Deploy your applications
- [Initial Setup Guide](getting-started/initial-setup.md) - Get started with the platform
- [Azure Resources Creation](operations/azure-resources-creation.md) - Azure CLI automation
- [CI/CD Setup](operations/cicd-setup.md) - Pipeline configuration

---

**Last Updated**: October 20, 2025  
**Diagram Format**: Mermaid.js  
**Total Diagrams**: 21 comprehensive diagrams covering all aspects of the platform

For questions about diagrams or to suggest improvements, please open an issue or pull request.
