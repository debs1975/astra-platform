# Prerequisites

Before setting up the Astra Platform, ensure you have the following prerequisites installed and configured.

## 🖥️ System Requirements

### Hardware Requirements
- **CPU**: 2+ cores recommended
- **Memory**: 8GB RAM minimum, 16GB recommended
- **Storage**: 10GB free disk space
- **Network**: Stable internet connection for Docker images and Azure API calls

### Operating System Support
- **macOS**: 10.14+ (Mojave or later)
- **Windows**: Windows 10/11 with WSL2
- **Linux**: Ubuntu 18.04+, RHEL 8+, or equivalent

## 🔧 Required Tools

### 1. Container Runtime
Choose one of the following:

#### Docker Desktop (Required for Minikube)
```bash
# macOS (using Homebrew)
brew install --cask docker

# Windows
# Download from https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe

# Linux (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

#### Minikube (Recommended - Kubernetes Local Cluster)
```bash
# macOS
brew install minikube

# Windows (using Chocolatey)
choco install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

**Verify Minikube Installation:**
```bash
minikube version
```

### 2. Kubernetes CLI (kubectl)
```bash
# macOS
brew install kubectl

# Windows (using Chocolatey)
choco install kubernetes-cli

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### 3. Helm Package Manager
```bash
# macOS
brew install helm

# Windows (using Chocolatey)
choco install kubernetes-helm

# Linux
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

### 4. Azure CLI
```bash
# macOS
brew install azure-cli

# Windows (using Chocolatey)
choco install azure-cli

# Linux (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### 5. Git Version Control
```bash
# macOS
brew install git

# Windows
# Download from https://git-scm.com/download/win

# Linux (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install git
```

### 6. jq (JSON Processor)
```bash
# macOS
brew install jq

# Windows (using Chocolatey)
choco install jq

# Linux (Ubuntu/Debian)
sudo apt-get install jq
```

### 7. Kustomize (Optional but Recommended)
```bash
# macOS
brew install kustomize

# Windows (using Chocolatey)
choco install kustomize

# Linux
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/
```

## ☁️ Azure Requirements

### 1. Azure Account
- Active Azure subscription
- Sufficient permissions to create resources
- Subscription contributor role or higher

### 2. Azure Service Principal
You'll need an Azure Service Principal with appropriate permissions:

```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac \
  --name "astra-platform-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/{subscription-id}"
```

### 3. Required Azure Permissions
The service principal needs the following Azure RBAC roles:
- **Contributor**: To create and manage resources
- **User Access Administrator**: To assign managed identity permissions (optional)

### 4. Azure Resource Providers
Ensure the following resource providers are registered:
```bash
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.ManagedIdentity
az provider register --namespace Microsoft.App
```

## 🐙 GitHub Requirements (for CI/CD)

### 1. GitHub Account
- GitHub account with repository access
- Ability to create GitHub Actions workflows

### 2. GitHub Secrets
Configure the following secrets in your GitHub repository:
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

### 3. GitHub Variables (Optional)
For AKS deployment:
- `AKS_CLUSTER_NAME`
- `AKS_RESOURCE_GROUP`

## 🔍 Verification Checklist

Before proceeding, verify your setup:

### Local Tools Verification
```bash
# Check Docker
docker --version
docker run hello-world

# Check Kubernetes cluster
kubectl cluster-info
kubectl get nodes

# Check Helm
helm version

# Check Azure CLI
az version
az account show

# Check other tools
git --version
jq --version
kustomize version
```

### Azure Verification
```bash
# Test Azure authentication
az login
az account list

# Test service principal (if created)
az login --service-principal \
  --username $AZURE_CLIENT_ID \
  --password $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID

# Check permissions
az role assignment list --assignee $AZURE_CLIENT_ID
```

### Kubernetes Cluster Verification
```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# Test cluster permissions
kubectl auth can-i create namespaces
kubectl auth can-i create deployments
```

## 🚨 Common Issues

### Docker Desktop Not Starting
- **Windows**: Enable WSL2 integration
- **macOS**: Check system requirements and available disk space
- **Linux**: Ensure user is in docker group: `sudo usermod -aG docker $USER`

### Minikube Not Starting
```bash
# Check system resources
minikube status

# Delete and recreate cluster
minikube delete
minikube start --driver=docker --cpus=4 --memory=8192

# Check driver availability
minikube start --driver=docker

# For VirtualBox (alternative driver)
minikube start --driver=virtualbox
```

### kubectl Not Connecting
```bash
# Check kubeconfig
kubectl config current-context
kubectl config get-contexts

# For Docker Desktop
kubectl config use-context docker-desktop

# For Minikube
kubectl config use-context minikube
```

### Azure CLI Authentication Issues
```bash
# Clear cached credentials
az account clear
az login --use-device-code

# Check tenant access
az account tenant list
```

## 📋 Next Steps

Once you have all prerequisites installed and verified:

1. ✅ Proceed to [Initial Setup Guide](initial-setup.md)
2. ✅ Or jump to [Quick Start](quick-start.md) for rapid deployment

## 📞 Support

If you encounter issues with prerequisites:
- Check the troubleshooting section for specific tools
- Refer to the official documentation for each tool
- Create an issue in the repository with your system details