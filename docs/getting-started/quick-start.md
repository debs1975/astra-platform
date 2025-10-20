# Quick Start Guide

Get the Astra Platform running in 15 minutes! This guide assumes you have all [prerequisites](prerequisites.md) installed.

## ⚡ TL;DR - One Command Setup

```bash
# Clone, setup credentials, and deploy
git clone <repository-url> && cd astra-platform
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
./scripts/install.sh && ./scripts/deploy.sh dev --wait
```

## 🚀 Step-by-Step Quick Setup

### 1. Clone Repository (1 minute)
```bash
git clone <repository-url>
cd astra-platform
```

### 2. Set Azure Credentials (2 minutes)
```bash
# Login to Azure
az login

# Create service principal (copy the output!)
az ad sp create-for-rbac --name "astra-sp-$(date +%s)" --role "Contributor" --scopes "/subscriptions/$(az account show --query id -o tsv)"

# Set environment variables (replace with your values)
export AZURE_CLIENT_ID="your-app-id"
export AZURE_CLIENT_SECRET="your-password"
export AZURE_TENANT_ID="your-tenant"
export AZURE_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
```

### 3. Start Kubernetes (2 minutes)
```bash
# Using Minikube (Recommended)
minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=20g

# Verify cluster is ready
kubectl cluster-info
kubectl get nodes

# If using Docker Desktop instead
# Ensure Kubernetes is enabled in Docker Desktop settings
# Go to Docker Desktop → Settings → Kubernetes → Enable Kubernetes
```

### 4. Install Astra Platform (5 minutes)
```bash
# Run installation script
./scripts/install.sh
```

Wait for all components to be ready:
```bash
# Check installation status
kubectl get pods -n crossplane-system
kubectl get xrd | grep astra
```

### 5. Deploy Development Environment (5 minutes)
```bash
# Update tenant ID and deploy
sed -i "s/YOUR_TENANT_ID/$AZURE_TENANT_ID/g" overlays/dev/platform-claim.yaml
./scripts/deploy.sh dev --wait
```

### 6. Get Your Application URL (1 minute)
```bash
# Get the deployed application URL
APP_URL=$(kubectl get xplatform astra-dev-platform -n astra-dev -o jsonpath='{.status.applicationUrl}')
echo "🎉 Your app is running at: https://$APP_URL"

# Test the application
curl -I "https://$APP_URL"
```

## ✅ Verification Checklist

Check these items to ensure everything is working:

```bash
# ✅ Crossplane is running
kubectl get pods -n crossplane-system --field-selector=status.phase=Running

# ✅ Azure provider is healthy
kubectl get providers -o wide

# ✅ XRDs are established
kubectl get xrd -o custom-columns=NAME:.metadata.name,ESTABLISHED:.status.conditions[0].status

# ✅ Platform is ready
kubectl get xplatform -n astra-dev -o wide

# ✅ Azure resources exist
az group list --query "[?starts_with(name, 'astra-dev')]" --output table
```

## 🎯 What You Just Created

In 15 minutes, you deployed:

| Resource | Azure Service | Purpose |
|----------|---------------|---------|
| **Resource Group** | `astra-dev-rg` | Container for all resources |
| **Managed Identity** | `astra-dev-mi` | RBAC authentication |
| **Key Vault** | `astra-dev-kv` | Secrets management |
| **Container Registry** | `astradevacr` | Docker image storage |
| **Storage Account** | `astradevsa` | Application data storage |
| **Container App** | `astra-dev-app` | Your running application |
| **Container Environment** | `astra-dev-cae` | Container Apps environment |

## 🔗 Useful Commands

```bash
# Check platform status
kubectl describe xplatform astra-dev-platform -n astra-dev

# View Azure resources
az resource list --resource-group astra-dev-rg --output table

# Get application logs
az containerapp logs show --name astra-dev-app --resource-group astra-dev-rg

# Scale application
kubectl patch xplatform astra-dev-platform -n astra-dev --type merge -p '{"spec":{"parameters":{"maxReplicas":5}}}'

# Deploy to staging
./scripts/deploy.sh staging --wait

# Clean up everything
./scripts/cleanup.sh --force --azure-only
```

## 🎨 Customize Your Deployment

### Change Container Image
```bash
# Deploy your own container image
./scripts/deploy.sh dev --image "your-registry/your-app:latest" --wait
```

### Scale Resources
Edit `overlays/dev/platform-claim.yaml`:
```yaml
spec:
  parameters:
    minReplicas: 2
    maxReplicas: 5
    cpu: 0.5
    memory: "1Gi"
```

Then redeploy:
```bash
kubectl apply -k overlays/dev
```

### Add Environment Variables
Modify the platform claim to include environment variables:
```yaml
spec:
  parameters:
    environmentVariables:
      - name: "API_URL"
        value: "https://api.example.com"
      - name: "LOG_LEVEL"
        value: "info"
```

## 🐛 Quick Troubleshooting

### Installation Failed?
```bash
# Check Crossplane logs
kubectl logs -n crossplane-system deployment/crossplane

# Check Azure provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-azure
```

### Deployment Stuck?
```bash
# Check platform status
kubectl describe xplatform astra-dev-platform -n astra-dev

# Check managed resources
kubectl get managedresources.pkg.crossplane.io | grep astra-dev
kubectl describe managedresource <resource-name>
```

### Azure Authentication Issues?
```bash
# Test Azure credentials
az login --service-principal \
  --username $AZURE_CLIENT_ID \
  --password $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID

# Check permissions
az role assignment list --assignee $AZURE_CLIENT_ID
```

### Application Not Accessible?
```bash
# Check container app status
az containerapp show --name astra-dev-app --resource-group astra-dev-rg --query "{Status:properties.provisioningState,URL:properties.configuration.ingress.fqdn}"

# Check DNS resolution
nslookup $(kubectl get xplatform astra-dev-platform -n astra-dev -o jsonpath='{.status.applicationUrl}')
```

## 🎉 Success!

If everything worked, you now have:
- ✅ A fully functional Azure Container Apps platform
- ✅ Infrastructure as Code with Crossplane
- ✅ Multi-environment support ready
- ✅ RBAC-secured Azure resources
- ✅ A running web application

## 📚 What's Next?

- **Learn More**: Read the [Platform Architecture](../architecture/platform-architecture.md)
- **Deploy Your App**: Follow [Application Deployment](../user-guides/application-deployment.md)
- **Set Up CI/CD**: Configure [GitHub Actions](../operations/cicd-setup.md)
- **Monitor Everything**: Set up [Monitoring](../user-guides/monitoring-observability.md)
- **Scale Production**: Deploy to [Multiple Environments](../user-guides/environment-management.md)

## 🆘 Need Help?

- 📖 **Full Documentation**: [Complete Setup Guide](initial-setup.md)
- 🐛 **Troubleshooting**: [Common Issues](../troubleshooting/common-issues.md)
- ❓ **FAQ**: [Frequently Asked Questions](../troubleshooting/faq.md)
- 💬 **Support**: Create an issue in the repository