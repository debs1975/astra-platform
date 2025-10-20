# Glossary

A comprehensive glossary of terms, concepts, and technologies used in the Astra Platform documentation.

## A

**Application**
A containerized software application deployed and managed by the Astra Platform. Applications run in Azure Container Apps and have access to integrated Azure services.

**Azure Container Apps**
A fully managed serverless container service from Microsoft Azure that enables you to run microservices and containerized applications on a serverless platform.

**Azure Container Registry (ACR)**
A managed, private Docker registry service based on the open-source Docker Registry 2.0. Used to store and manage container images for deployment.

**Azure Key Vault**
A cloud service for securely storing and accessing secrets, keys, and certificates. Integrated with the Astra Platform for secrets management.

**Azure Provider**
The Crossplane provider that enables management of Azure resources through Kubernetes APIs. Translates Crossplane resource definitions into Azure ARM templates.

**Azure Resource Manager (ARM)**
The deployment and management service for Azure. Provides a management layer that enables you to create, update, and delete resources in your Azure account.

## C

**Claim**
In Crossplane terminology, a claim is a request for a resource that an application developer makes. Claims are portable across different cloud providers and environments.

**Composition**
A Crossplane resource that defines how to provision infrastructure. Compositions are templates that describe how Composite Resource Definitions (XRDs) should be implemented using managed resources.

**Composite Resource**
A higher-level resource that composes multiple managed resources. Composite resources are defined by Composite Resource Definitions (XRDs) and created by Compositions.

**Composite Resource Definition (XRD)**
A schema that defines the structure and configuration options for a composite resource. Similar to Kubernetes Custom Resource Definitions but for infrastructure.

**Container App Environment**
An Azure service that provides a secure boundary around a group of container apps. Contains shared resources like virtual networks and log analytics workspaces.

**Control Plane**
The set of processes that control Kubernetes nodes and manage the cluster. In Crossplane context, it refers to the management layer that reconciles desired state with actual state.

**Crossplane**
An open-source Kubernetes add-on that enables platform teams to assemble infrastructure from multiple vendors and expose higher level self-service APIs for application teams.

**Custom Resource Definition (CRD)**
A way to extend Kubernetes APIs by defining custom resources. The Astra Platform uses CRDs to define platform-specific resources.

## D

**Drift Detection**
The process of identifying differences between the desired state (as defined in configuration) and the actual state of deployed resources.

**Dry Run**
A mode of operation where commands are executed without making actual changes, allowing you to preview what would happen without affecting the real environment.

## E

**Environment**
A logical grouping of resources that represents a stage in the software development lifecycle (development, staging, production, etc.).

**External Secret Operator**
A Kubernetes operator that integrates external secret management systems (like Azure Key Vault) with Kubernetes secrets.

## F

**Function Composition**
The practice of building complex infrastructure components by combining simpler, reusable building blocks. Central to the Astra Platform's architecture.

## G

**GitOps**
A set of practices that use Git repositories as the source of truth for defining the desired state of system configurations and applications.

## H

**Helm**
A package manager for Kubernetes that uses charts (packages) to define, install, and upgrade Kubernetes applications.

**Health Check**
Automated tests that verify whether an application or service is running correctly and responding to requests.

## I

**Infrastructure as Code (IaC)**
The practice of managing and provisioning computing infrastructure through machine-readable definition files, rather than physical hardware configuration or interactive configuration tools.

**Ingress**
A Kubernetes resource that manages external access to services in a cluster, typically HTTP/HTTPS routing rules.

## K

**kubectl**
The command-line tool for interacting with Kubernetes clusters. Used to deploy applications, inspect cluster resources, and view logs.

**Kubernetes**
An open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications.

**Kustomize**
A tool for customizing Kubernetes configurations. It allows you to manage configuration variants for different environments without duplicating YAML files.

## L

**Label**
Key-value pairs attached to Kubernetes objects that are used to organize and select subsets of objects.

**Lifecycle**
The sequence of stages that a resource goes through from creation to deletion, including provisioning, configuration, updates, and decommissioning.

## M

**Managed Identity**
An Azure service that provides automatically managed identities for Azure resources, eliminating the need to store credentials in code or configuration files.

**Managed Resource**
In Crossplane terminology, a resource that represents a single piece of infrastructure from a cloud provider (e.g., an Azure Storage Account).

**Manifest**
A YAML or JSON file that describes a desired resource configuration in Kubernetes or Crossplane.

**Multi-tenancy**
The ability to serve multiple customers or teams from a single instance of software, with proper isolation between tenants.

## N

**Namespace**
A way to divide cluster resources between multiple users or applications. Provides a scope for names and can be used to apply policies.

**Naming Convention**
Standardized rules for naming resources to ensure consistency, clarity, and organization across the platform.

## O

**Observability**
The ability to understand the internal state of a system based on the data it generates, including metrics, logs, and traces.

**Operator**
A method of packaging, deploying, and managing a Kubernetes application using custom controllers and resources.

**Overlay**
In Kustomize terminology, a directory containing a kustomization.yaml file that refers to another kustomization directory as its base.

## P

**Platform**
In the Astra Platform context, a complete set of integrated Azure services that provides a foundation for deploying and running applications.

**Provider**
A Crossplane component that enables the management of resources for a specific cloud provider or service. The Azure Provider manages Azure resources.

**ProviderConfig**
A Crossplane resource that configures how a provider should authenticate and connect to its target API (e.g., Azure ARM API).

## Q

**Quality Gate**
Automated checks that must pass before code or infrastructure changes can be promoted to the next stage in the deployment pipeline.

## R

**Reconciliation**
The process by which a controller ensures that the actual state of resources matches the desired state defined in the configuration.

**Resource Group**
An Azure container that holds related resources for an Azure solution. Used to organize and manage Azure resources as a group.

**Rolling Update**
A deployment strategy where old versions of an application are incrementally replaced with new versions without downtime.

## S

**Secret**
Sensitive information such as passwords, tokens, or keys that should not be exposed in configuration files or container images.

**Service Principal**
An identity created for use with applications, hosted services, and automated tools to access Azure resources.

**Sidecar**
A helper container that runs alongside the main application container, typically providing supporting functionality like logging or monitoring.

**State**
The current configuration and status of resources in the system. Can be "desired state" (what you want) or "actual state" (what currently exists).

## T

**Tenant**
In Azure terminology, a dedicated instance of Azure Active Directory that an organization receives when it signs up for a Microsoft cloud service.

**Template**
A reusable configuration pattern that can be customized for different environments or use cases.

## V

**Virtual Network (VNet)**
An Azure service that provides private network connectivity between Azure resources and enables secure communication.

## X

**XR (Composite Resource)**
Short for "Composite Resource" - a high-level resource composed of multiple managed resources in Crossplane.

**XRD (Composite Resource Definition)**
Short for "Composite Resource Definition" - defines the schema for composite resources in Crossplane.

## Y

**YAML**
A human-readable data serialization standard used for configuration files in Kubernetes and Crossplane.

## Z

**Zone**
An Azure availability zone - physically separate locations within an Azure region that provide redundancy and high availability.

---

## Common Acronyms

| Acronym | Full Form | Description |
|---------|-----------|-------------|
| ACR | Azure Container Registry | Managed Docker registry service |
| AKV | Azure Key Vault | Secret management service |
| ARM | Azure Resource Manager | Azure's deployment service |
| CA | Container Apps | Azure's serverless container service |
| CRD | Custom Resource Definition | Kubernetes API extension |
| IaC | Infrastructure as Code | Managing infrastructure through code |
| RBAC | Role-Based Access Control | Permission management system |
| SLA | Service Level Agreement | Performance guarantee contract |
| SLI | Service Level Indicator | Measurable metric of service performance |
| SLO | Service Level Objective | Target value for SLI |
| TLS | Transport Layer Security | Encryption protocol for secure communication |
| VNet | Virtual Network | Private network in Azure |
| XRD | Composite Resource Definition | Crossplane resource schema definition |

---

## Related Concepts

### Crossplane Concepts
- **Provider**: Manages resources for a specific platform
- **Composition**: Template for creating resources
- **Claim**: Request for a resource
- **Managed Resource**: Single cloud resource
- **Composite Resource**: Collection of managed resources

### Azure Concepts
- **Subscription**: Billing and management boundary
- **Resource Group**: Container for related resources
- **Tenant**: Azure AD instance
- **Region**: Geographic location of data centers
- **Availability Zone**: Isolated location within region

### Kubernetes Concepts
- **Pod**: Smallest deployable unit
- **Service**: Network endpoint for pods
- **Deployment**: Manages pod replicas
- **ConfigMap**: Configuration data storage
- **Secret**: Sensitive data storage

---

*This glossary is regularly updated to include new terms and concepts. If you encounter a term not listed here, please refer to the main documentation or contribute to this glossary through our [Contributing Guidelines](../development/contributing.md).*