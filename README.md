# Astra Platform 🚀# Astra Platform 🚀



[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)[![Azure DevOps Build](https://dev.azure.com/your-org/astra-platform/_apis/build/status/validate-pipeline)](https://dev.azure.com/your-org/astra-platform/_build)

[![Release](https://img.shields.io/github/v/release/your-org/astra-platform)](https://github.com/your-org/astra-platform/releases)

A Kubernetes-native infrastructure platform for Azure Container Apps using Crossplane. Deploy, manage, and scale containerized applications across multiple environments with declarative infrastructure as code.[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)



## 📚 Complete DocumentationA Kubernetes-native infrastructure platform for Azure Container Apps using Crossplane. Deploy, manage, and scale containerized applications across multiple environments with declarative infrastructure as code.



**All project documentation is centralized in the [docs/](docs/) folder.**## ✨ Features



👉 **Start here**: [Documentation Index](docs/README.md)- 🏗️ **Crossplane-Native**: Kubernetes-native infrastructure management

- ☁️ **Azure Container Apps**: Serverless container platform with auto-scaling

## 🚀 Quick Start- 🔐 **Security First**: Managed identities, RBAC, Key Vault integration

- 🌍 **Multi-Environment**: Development, staging, and production deployments

```bash- 🚀 **CI/CD Ready**: Azure DevOps pipelines with comprehensive automation

# 1. Clone the repository- 📊 **Observable**: Built-in monitoring and logging capabilities

git clone https://github.com/your-org/astra-platform.git- 🔧 **Cross-Platform**: Works on macOS, Windows, and Linux

cd astra-platform- 📚 **Well-Documented**: Comprehensive guides and troubleshooting resources



# 2. Set Azure credentials## 🚀 Quick Start

export AZURE_CLIENT_ID="your-client-id"

export AZURE_CLIENT_SECRET="your-client-secret"Get the Astra Platform running in 15 minutes:

export AZURE_TENANT_ID="your-tenant-id"

export AZURE_SUBSCRIPTION_ID="your-subscription-id"```bash

# 1. Clone the repository

# 3. Install platformgit clone https://github.com/your-org/astra-platform.git

./scripts/install.shcd astra-platform



# 4. Deploy to development# 2. Set Azure credentials

./scripts/deploy.sh dev --waitexport AZURE_CLIENT_ID="your-client-id"

```export AZURE_CLIENT_SECRET="your-client-secret"

export AZURE_TENANT_ID="your-tenant-id"

## 📖 Key Documentationexport AZURE_SUBSCRIPTION_ID="your-subscription-id"



| Topic | Link | Description |# 3. Install platform

|-------|------|-------------|./scripts/install.sh

| **Getting Started** | [docs/getting-started/](docs/getting-started/) | Prerequisites, setup guides, and quick start |

| **Architecture** | [docs/architecture/](docs/architecture/) | Platform architecture and design |# 4. Deploy to development

| **User Guides** | [docs/user-guides/](docs/user-guides/) | Application deployment and environment management |./scripts/deploy.sh dev --wait

| **Operations** | [docs/operations/](docs/operations/) | CI/CD setup and operational guides |

| **Reference** | [docs/reference/](docs/reference/) | API reference, scripts, and examples |# 5. Get your application URL

| **Development** | [docs/development/](docs/development/) | Contributing, testing, and development setup |./scripts/deploy.sh dev --urls

| **Planning** | [docs/planning/](docs/planning/) | Project planning, prompts, and execution plans |```

| **Troubleshooting** | [docs/troubleshooting/](docs/troubleshooting/) | Common issues and debugging |

Your containerized application will be running on Azure Container Apps with:

## ✨ Key Features- ✅ Automatic HTTPS with managed certificates

- ✅ Auto-scaling based on demand (1-10 replicas)

- 🏗️ **Crossplane-Native**: Kubernetes-native infrastructure management- ✅ Managed identity for secure Azure service access

- ☁️ **Azure Container Apps**: Serverless container platform with auto-scaling- ✅ Container registry for image storage

- 🔐 **Security First**: Managed identities, RBAC, Key Vault integration- ✅ Key Vault for secrets management

- 🌍 **Multi-Environment**: Development, staging, and production deployments- ✅ Blob storage for application data

- 🚀 **CI/CD Ready**: Azure DevOps pipelines with comprehensive automation

- 📊 **Observable**: Built-in monitoring and logging capabilities## 🏗️ Architecture

- 🔧 **Cross-Platform**: Works on macOS, Windows, and Linux

```mermaid

## 📂 Project Structuregraph TB

    subgraph "Local Environment"

```        K8s[Kubernetes<br/>Minikube/Docker Desktop]

astra-platform/        CP[Crossplane Control Plane]

├── docs/                    # 📚 Complete documentation (START HERE)        XRD[Platform XRDs]

├── packages/               # Crossplane XRDs and Compositions    end

├── overlays/              # Environment-specific configurations (dev/staging/prod)    

├── pipelines/             # Azure DevOps CI/CD pipelines    subgraph "Azure Cloud"

├── scripts/               # Automation scripts        subgraph "astra-dev-*"

└── tests/                # Test suites (unit, integration, e2e)            RG1[Resource Group]

```            MI1[Managed Identity]

            KV1[Key Vault]

## 📞 Support            ACR1[Container Registry]

            SA1[Storage Account]

- **📖 Full Documentation**: [docs/README.md](docs/README.md)            CA1[Container App]

- **🚀 Quick Start Guide**: [docs/getting-started/quick-start.md](docs/getting-started/quick-start.md)        end

- **🐛 Issues**: Create an issue in the GitHub repository        

- **💬 Discussions**: Use GitHub Discussions for questions        subgraph "astra-prod-*"

            RG2[Resource Group]

## 📄 License            MI2[Managed Identity]

            KV2[Key Vault]

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.            ACR2[Container Registry]

            SA2[Storage Account]

---            CA2[Container App]

        end

**Built with ❤️ by the Astra Platform Team**    end

    

*For complete documentation, guides, and references, see [docs/README.md](docs/README.md)*    CP --> XRD

    XRD --> RG1
    XRD --> RG2
    RG1 --> MI1 --> KV1
    RG1 --> ACR1 --> SA1 --> CA1
    RG2 --> MI2 --> KV2
    RG2 --> ACR2 --> SA2 --> CA2
```

The platform uses Crossplane running locally to manage Azure resources declaratively. Each environment gets its own isolated set of Azure resources with proper RBAC and security boundaries.

## � Project Structure

```
astra-platform/
├── docs/                    # Complete documentation
├── packages/               # Crossplane XRDs and Compositions
│   ├── containerapp/      # Container Apps resource definitions
│   ├── containerregistry/ # Azure Container Registry
│   ├── keyvault/         # Azure Key Vault
│   ├── managedidentity/  # Azure Managed Identity
│   ├── platform/         # Platform orchestration
│   ├── resourcegroup/    # Azure Resource Groups
│   └── storage/          # Azure Storage Accounts
├── overlays/              # Environment-specific configurations
│   ├── dev/              # Development environment
│   ├── staging/          # Staging environment
│   └── prod/             # Production environment
├── pipelines/             # Azure DevOps pipelines
│   ├── azure-pipelines.yml # Main CI/CD pipeline
│   └── README.md         # Pipeline documentation
├── scripts/               # Automation scripts
│   ├── install.sh        # Platform installation
│   ├── deploy.sh         # Deployment automation
│   └── test-all.sh      # Comprehensive testing
└── tests/                # Test suites
    ├── unit/             # Unit tests
    ├── integration/      # Integration tests
    └── e2e/              # End-to-end tests
```

## 📋 Prerequisites

Before getting started, ensure you have:

- **Kubernetes Cluster**: Minikube (recommended) or Docker Desktop
- **Azure Account**: Active subscription with Contributor permissions
- **Tools**: kubectl, helm, Azure CLI, Docker

For detailed setup instructions, see:
- [Prerequisites Guide](docs/getting-started/prerequisites.md)
- [Minikube Setup Guide](docs/getting-started/minikube-setup.md)

## 📖 Documentation

### 🚀 Getting Started
- [**Prerequisites**](docs/getting-started/prerequisites.md) - Required tools and setup
- [**Minikube Setup**](docs/getting-started/minikube-setup.md) - Minikube configuration guide
- [**Initial Setup**](docs/getting-started/initial-setup.md) - Complete setup guide
- [**Quick Start**](docs/getting-started/quick-start.md) - 15-minute deployment
- [**GitHub Setup**](docs/GITHUB-SETUP.md) - Push your platform to GitHub

### 🏗️ Architecture
- [**Platform Architecture**](docs/architecture/platform-architecture.md) - Technical overview
- [**Crossplane Components**](docs/architecture/crossplane-components.md) - XRDs and Compositions

### 👥 User Guides
- [**Application Deployment**](docs/user-guides/application-deployment.md) - Deploy your apps
- [**Environment Management**](docs/user-guides/environment-management.md) - Manage environments
- [**Configuration**](docs/user-guides/configuration-management.md) - Configure platform

### ⚙️ Operations
- [**CI/CD Setup**](docs/operations/cicd-setup.md) - Azure DevOps pipeline configuration
- [**Azure Resources Creation**](docs/operations/azure-resources-creation.md) - Azure CLI automation guide
- [**Secret Management**](docs/operations/secret-management.md) - Secure credential handling

### 🐛 Troubleshooting
- [**Common Issues**](docs/troubleshooting/common-issues.md) - FAQ and solutions
- [**Debugging Guide**](docs/troubleshooting/debugging.md) - Step-by-step troubleshooting

### 📚 Additional Resources
- [**Minikube Primary Setup**](docs/MINIKUBE-PRIMARY-SETUP.md) - Complete Minikube migration summary
- [**GitHub Setup Guide**](docs/GITHUB-SETUP.md) - Repository setup instructions

### 📖 Complete Documentation
See the [Documentation Index](docs/README.md) for all available guides.

## 🛠️ Usage Examples

### Deploy Your Own Application
```bash
# Build and push your image
docker build -t your-app:v1.0.0 .
az acr login --name astradevacr
docker tag your-app:v1.0.0 astradevacr.azurecr.io/your-app:v1.0.0
docker push astradevacr.azurecr.io/your-app:v1.0.0

# Deploy to development
./scripts/deploy.sh dev --image "astradevacr.azurecr.io/your-app:v1.0.0" --wait

# Scale for production
./scripts/deploy.sh prod --image "astradevacr.azurecr.io/your-app:v1.0.0" --wait
```

### Multi-Environment Deployment
```bash
# Deploy to all environments
./scripts/deploy.sh dev --wait
./scripts/deploy.sh staging --wait  
./scripts/deploy.sh prod --wait

# Check status across environments
kubectl get xplatform -A
```

### Custom Configuration
```yaml
# Modify overlays/prod/platform-claim.yaml
spec:
  parameters:
    minReplicas: 5
    maxReplicas: 20
    cpu: 2.0
    memory: "4Gi"
    containerImage: "your-registry/app:v2.0.0"
```

## 🔧 Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/install.sh` | Install Crossplane and platform | `./scripts/install.sh` |
| `scripts/deploy.sh` | Deploy to environment | `./scripts/deploy.sh dev --wait` |
| `scripts/manage-secrets.sh` | Manage Azure credentials | `./scripts/manage-secrets.sh create-sp` |
| `scripts/cleanup.sh` | Clean up resources | `./scripts/cleanup.sh --force` |

## 🌍 Multi-Environment Support

The platform supports multiple environments with different configurations:

| Environment | Namespace | Resources | Use Case |
|------------|-----------|-----------|----------|
| **dev** | `astra-dev` | 0.25 CPU, 0.5Gi RAM, 1-3 replicas | Development and testing |
| **staging** | `astra-staging` | 0.5 CPU, 1Gi RAM, 2-5 replicas | Pre-production validation |
| **prod** | `astra-prod` | 1.0 CPU, 2Gi RAM, 3-10 replicas | Production workloads |

Each environment gets its own:
- Azure Resource Group
- Managed Identity with scoped permissions
- Container Registry
- Key Vault for secrets
- Storage Account for data
- Container App for the application

## 🔐 Security Features

- **🔑 Managed Identity**: Passwordless authentication to Azure services
- **🔒 RBAC Integration**: Least-privilege access controls
- **🛡️ Key Vault**: Centralized secrets management
- **🔐 Network Security**: HTTPS-only ingress with managed certificates
- **👤 Azure AD Integration**: Integration with organizational identity
- **📝 Audit Logging**: Comprehensive audit trails

## 🚀 CI/CD Integration

### Azure DevOps Pipeline (Included)
- **Validation**: Automatic YAML and Crossplane resource validation
- **Testing**: Comprehensive unit, integration, and E2E testing
- **Security**: Secret detection and security compliance scanning
- **Build**: Crossplane package creation and artifact publishing
- **Deploy**: Multi-environment deployment (dev → staging → prod)
- **Release**: Automated GitHub release creation and packaging

### Pipeline Features
- **Multi-Stage**: 6 comprehensive stages with proper dependencies
- **Environment Management**: Separate environments with approval controls
- **Security First**: Comprehensive secret scanning and security validation
- **Cross-Platform**: Works with Azure Repos, GitHub, and other Git providers

## 📊 Monitoring & Observability

- **Container Apps Metrics**: Built-in CPU, memory, and request metrics
- **Azure Monitor Integration**: Centralized logging and monitoring
- **Custom Dashboards**: Pre-configured monitoring dashboards
- **Alerting**: Configurable alerts for critical events
- **Log Analytics**: Centralized log aggregation

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](docs/development/contributing.md) for details.

### Development Setup
```bash
# Fork and clone the repository
git clone https://github.com/your-username/astra-platform.git
cd astra-platform

# Set up development environment
./scripts/install.sh

# Make changes and test
./scripts/deploy.sh dev --wait

# Run validation
kubectl apply --dry-run=client -k overlays/dev
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **📖 Documentation**: [Complete Documentation](docs/README.md)
- **🐛 Issues**: [GitHub Issues](https://github.com/your-org/astra-platform/issues)
- **💬 Discussions**: [GitHub Discussions](https://github.com/your-org/astra-platform/discussions)
- **📧 Email**: platform-support@your-org.com

## 🎯 What's Next?

After deploying your first environment:

1. **Deploy Your Application**: Follow the [Application Deployment Guide](docs/user-guides/application-deployment.md)
2. **Set Up CI/CD**: Configure [Azure DevOps Pipeline](docs/operations/cicd-setup.md) for automated deployments
3. **Add Monitoring**: Set up [monitoring and alerting](docs/user-guides/monitoring-observability.md)
4. **Scale to Production**: Deploy to [multiple environments](docs/user-guides/environment-management.md)

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=your-org/astra-platform&type=Date)](https://star-history.com/#your-org/astra-platform&Date)

---

**Built with ❤️ by the Astra Platform Team**

*Empowering developers to deploy and scale applications on Azure with Kubernetes-native infrastructure management.*