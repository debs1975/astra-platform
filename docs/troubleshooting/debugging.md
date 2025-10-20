# Troubleshooting Guide

This comprehensive troubleshooting guide helps you diagnose and resolve common issues with the Astra Platform.

## 🚨 Quick Diagnosis

### Platform Health Check
Run this quick health check script to identify issues:

```bash
#!/bin/bash
echo "🔍 Astra Platform Health Check"
echo "================================"

# Check Kubernetes cluster
echo "📋 Kubernetes Cluster:"
kubectl cluster-info --request-timeout=10s || echo "❌ Cluster not accessible"

# Check Crossplane
echo "📋 Crossplane Status:"
kubectl get pods -n crossplane-system --field-selector=status.phase=Running | wc -l
kubectl get providers -o wide

# Check XRDs
echo "📋 XRDs Status:"
kubectl get xrd -o custom-columns=NAME:.metadata.name,ESTABLISHED:.status.conditions[0].status

# Check Platform Claims
echo "📋 Platform Claims:"
for ns in astra-dev astra-staging astra-prod; do
  if kubectl get ns $ns &>/dev/null; then
    echo "Environment: $ns"
    kubectl get xplatform -n $ns -o wide 2>/dev/null || echo "  No platform claims"
  fi
done

# Check Azure Resources
echo "📋 Azure Resources:"
az group list --query "[?starts_with(name, 'astra-')]" --output table 2>/dev/null || echo "❌ Azure CLI not accessible"

echo "✅ Health check complete"
```

## 🔧 Installation Issues

### Crossplane Installation Fails

#### Symptom: Helm install fails
```bash
Error: failed to install crossplane: context deadline exceeded
```

**Solution**:
```bash
# Check cluster resources
kubectl top nodes
kubectl describe nodes

# Increase timeout and retry
helm install crossplane crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace \
  --timeout 10m \
  --wait

# Check pod status
kubectl get pods -n crossplane-system
kubectl describe pod -n crossplane-system -l app=crossplane
```

#### Symptom: Azure Provider not healthy
```bash
kubectl get providers
NAME             INSTALLED   HEALTHY   PACKAGE
provider-azure   True        False     xpkg.upbound.io/upbound/provider-azure...
```

**Solution**:
```bash
# Check provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-azure

# Common fixes:
# 1. Check provider version compatibility
kubectl describe provider provider-azure

# 2. Delete and recreate provider
kubectl delete provider provider-azure
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure
spec:
  package: xpkg.upbound.io/upbound/provider-azure-containerapp:v0.36.0
EOF

# 3. Check ProviderConfig
kubectl get providerconfig
kubectl describe providerconfig default
```

### Script Execution Issues

#### Symptom: Permission denied
```bash
./scripts/install.sh
bash: ./scripts/install.sh: Permission denied
```

**Solution**:
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Or run with bash
bash scripts/install.sh
```

#### Symptom: Azure credentials error
```bash
Error: Azure credentials not set in environment variables
```

**Solution**:
```bash
# Verify environment variables
echo $AZURE_CLIENT_ID
echo $AZURE_TENANT_ID
echo $AZURE_SUBSCRIPTION_ID
# Don't echo AZURE_CLIENT_SECRET for security

# Set missing variables
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_SUBSCRIPTION_ID="your-subscription-id"

# Test authentication
az login --service-principal \
  --username $AZURE_CLIENT_ID \
  --password $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID
```

## 🚀 Deployment Issues

### Platform Claim Stuck in Creating

#### Symptom: Platform never becomes ready
```bash
kubectl get xplatform -n astra-dev
NAME                   READY   SYNCED   AGE
astra-dev-platform     False   False    15m
```

**Diagnosis**:
```bash
# Check platform claim status
kubectl describe xplatform astra-dev-platform -n astra-dev

# Check managed resources
kubectl get managedresources.pkg.crossplane.io | grep astra-dev

# Check individual resource status
kubectl describe managedresource <resource-name>
```

**Common Causes & Solutions**:

1. **Azure Authentication Issues**:
```bash
# Check ProviderConfig
kubectl describe providerconfig default

# Verify secret exists
kubectl get secret azure-secret -n crossplane-system

# Check secret content (base64 decode)
kubectl get secret azure-secret -n crossplane-system -o jsonpath='{.data.creds}' | base64 -d | jq
```

2. **Azure Resource Quota Exceeded**:
```bash
# Check Azure quotas
az vm list-usage --location "Central India" --output table
az network list-usages --location "Central India" --output table

# Request quota increase if needed
# Portal: Support + troubleshooting → New support request → Service and subscription limits
```

3. **Naming Conflicts**:
```bash
# Check for existing Azure resources
az group show --name astra-dev-rg
az storage account check-name --name astradevsa
az acr check-name --name astradevacr

# If conflicts exist, change namingPrefix in platform claim
kubectl patch xplatform astra-dev-platform -n astra-dev --type merge -p '{"spec":{"parameters":{"namingPrefix":"astra-dev-v2"}}}'
```

### Container App Not Starting

#### Symptom: Container app exists but not accessible
```bash
curl: (7) Failed to connect to astra-dev-app.xxx.centralindia.azurecontainerapps.io
```

**Diagnosis**:
```bash
# Check container app status
az containerapp show --name astra-dev-app --resource-group astra-dev-rg \
  --query "{Status:properties.provisioningState,Health:properties.runningStatus,URL:properties.configuration.ingress.fqdn}"

# Check container app logs
az containerapp logs show --name astra-dev-app --resource-group astra-dev-rg --follow

# Check revision status
az containerapp revision list --name astra-dev-app --resource-group astra-dev-rg --output table
```

**Solutions**:

1. **Image Pull Issues**:
```bash
# Check if image exists and is accessible
docker pull mcr.microsoft.com/azuredocs/containerapps-helloworld:latest

# Verify container registry access
az acr repository list --name astradevacr
az acr repository show-tags --name astradevacr --repository your-app
```

2. **Resource Constraints**:
```bash
# Check container app configuration
az containerapp show --name astra-dev-app --resource-group astra-dev-rg \
  --query "properties.template.containers[0].resources"

# Increase resources if needed
kubectl patch xplatform astra-dev-platform -n astra-dev --type merge -p '{
  "spec": {
    "parameters": {
      "cpu": 0.5,
      "memory": "1Gi"
    }
  }
}'
```

3. **Network/Ingress Issues**:
```bash
# Check ingress configuration
az containerapp ingress show --name astra-dev-app --resource-group astra-dev-rg

# Check DNS resolution
nslookup astra-dev-app.xxx.centralindia.azurecontainerapps.io

# Test internal connectivity
az containerapp exec --name astra-dev-app --resource-group astra-dev-rg --command "curl localhost:80"
```

## 🔐 Authentication & Authorization Issues

### Azure Authentication Failures

#### Symptom: Crossplane can't create Azure resources
```bash
Error: Unauthorized - The client does not have authorization to perform action
```

**Solution**:
```bash
# Check service principal permissions
az role assignment list --assignee $AZURE_CLIENT_ID --output table

# Add missing permissions
az role assignment create \
  --assignee $AZURE_CLIENT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID"

# For specific resource groups
az role assignment create \
  --assignee $AZURE_CLIENT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/astra-dev-rg"
```

### Managed Identity Issues

#### Symptom: Container app can't access Key Vault or Storage
```bash
Error: Access denied. The user or application does not have access to this resource
```

**Solution**:
```bash
# Check managed identity exists
az identity show --name astra-dev-mi --resource-group astra-dev-rg

# Check role assignments
IDENTITY_PRINCIPAL_ID=$(az identity show --name astra-dev-mi --resource-group astra-dev-rg --query principalId -o tsv)
az role assignment list --assignee $IDENTITY_PRINCIPAL_ID --output table

# Manually assign roles if missing
az role assignment create \
  --assignee $IDENTITY_PRINCIPAL_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/astra-dev-rg/providers/Microsoft.Storage/storageAccounts/astradevsa"

az role assignment create \
  --assignee $IDENTITY_PRINCIPAL_ID \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/astra-dev-rg/providers/Microsoft.KeyVault/vaults/astra-dev-kv"
```

## 🌐 Networking Issues

### DNS Resolution Problems

#### Symptom: Can't resolve container app URL
```bash
nslookup astra-dev-app.xxx.centralindia.azurecontainerapps.io
** server can't find astra-dev-app.xxx.centralindia.azurecontainerapps.io: NXDOMAIN
```

**Solution**:
```bash
# Check if container app is running
az containerapp show --name astra-dev-app --resource-group astra-dev-rg \
  --query "properties.runningStatus"

# Check ingress configuration
az containerapp ingress show --name astra-dev-app --resource-group astra-dev-rg

# Verify FQDN
kubectl get xplatform astra-dev-platform -n astra-dev -o jsonpath='{.status.applicationUrl}'

# Try different DNS servers
nslookup astra-dev-app.xxx.centralindia.azurecontainerapps.io 8.8.8.8
```

### SSL/TLS Certificate Issues

#### Symptom: SSL certificate errors
```bash
curl: (60) SSL certificate problem: unable to get local issuer certificate
```

**Solution**:
```bash
# Check certificate details
openssl s_client -connect astra-dev-app.xxx.centralindia.azurecontainerapps.io:443 -servername astra-dev-app.xxx.centralindia.azurecontainerapps.io

# Container Apps use managed certificates, no action needed
# For testing, use -k flag with curl
curl -k https://astra-dev-app.xxx.centralindia.azurecontainerapps.io

# Check ingress TLS configuration
az containerapp ingress show --name astra-dev-app --resource-group astra-dev-rg \
  --query "tls"
```

## 🗄️ Resource Management Issues

### Storage Account Access Issues

#### Symptom: Can't access blob storage
```bash
Error: This request is not authorized to perform this operation
```

**Solution**:
```bash
# Check storage account exists
az storage account show --name astradevsa --resource-group astra-dev-rg

# Check container exists
az storage container list --account-name astradevsa --auth-mode login

# Test access with managed identity
# (from within container app)
curl -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/"
```

### Key Vault Access Issues

#### Symptom: Can't retrieve secrets from Key Vault
```bash
Error: The user, group or application does not have secrets get permission
```

**Solution**:
```bash
# Check Key Vault exists and access policies
az keyvault show --name astra-dev-kv --resource-group astra-dev-rg

# List access policies
az keyvault show --name astra-dev-kv --resource-group astra-dev-rg \
  --query "properties.accessPolicies"

# Check managed identity has access
IDENTITY_PRINCIPAL_ID=$(az identity show --name astra-dev-mi --resource-group astra-dev-rg --query principalId -o tsv)
az keyvault set-policy --name astra-dev-kv \
  --object-id $IDENTITY_PRINCIPAL_ID \
  --secret-permissions get list
```

## 🔄 Update & Scaling Issues

### Application Update Failures

#### Symptom: New image version not deploying
```bash
# Platform claim updated but container still running old image
```

**Solution**:
```bash
# Check if update was applied
kubectl describe xplatform astra-dev-platform -n astra-dev

# Force container app restart
az containerapp revision restart --name astra-dev-app --resource-group astra-dev-rg

# Check revision history
az containerapp revision list --name astra-dev-app --resource-group astra-dev-rg --output table

# Manually trigger new revision
az containerapp update --name astra-dev-app --resource-group astra-dev-rg \
  --image "your-new-image:tag"
```

### Scaling Issues

#### Symptom: Application not scaling as expected
```bash
# Load increased but replicas stay the same
```

**Solution**:
```bash
# Check scaling configuration
az containerapp show --name astra-dev-app --resource-group astra-dev-rg \
  --query "properties.template.scale"

# Check current replica count
az containerapp replica list --name astra-dev-app --resource-group astra-dev-rg

# Update scaling parameters
kubectl patch xplatform astra-dev-platform -n astra-dev --type merge -p '{
  "spec": {
    "parameters": {
      "minReplicas": 2,
      "maxReplicas": 10
    }
  }
}'

# Check scaling rules (if any)
az containerapp show --name astra-dev-app --resource-group astra-dev-rg \
  --query "properties.template.scale.rules"
```

## 🧹 Cleanup Issues

### Resources Not Deleting

#### Symptom: Azure resources remain after cleanup
```bash
# cleanup.sh completed but resources still exist
```

**Solution**:
```bash
# Check managed resources status
kubectl get managedresources.pkg.crossplane.io | grep astra-dev

# Force delete stuck managed resources
kubectl patch managedresource <resource-name> -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl delete managedresource <resource-name>

# Manual Azure cleanup
az group delete --name astra-dev-rg --yes --no-wait

# Check for orphaned resources
az resource list --query "[?starts_with(name, 'astra-dev')]" --output table
```

### Crossplane Not Removing

#### Symptom: Can't uninstall Crossplane
```bash
Error: uninstallation completed with 1 error(s): timed out waiting for the condition
```

**Solution**:
```bash
# Check for remaining XRDs
kubectl get xrd

# Force delete XRDs
kubectl patch xrd xplatforms.astra.platform -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl delete xrd --all

# Remove Crossplane with force
helm uninstall crossplane -n crossplane-system --timeout 10m

# Clean up namespace
kubectl delete namespace crossplane-system --force --grace-period=0
```

## 📊 Performance Issues

### Slow Deployment Times

#### Symptom: Platform takes longer than expected to deploy
```bash
# Deployment takes >15 minutes
```

**Diagnosis & Solutions**:
```bash
# Check cluster resources
kubectl top nodes
kubectl describe nodes

# Check Crossplane performance
kubectl logs -n crossplane-system deployment/crossplane | grep -i "slow\|timeout\|error"

# Monitor managed resource creation
watch 'kubectl get managedresources.pkg.crossplane.io | grep astra-dev'

# Optimize by:
# 1. Increase cluster resources
# 2. Use faster storage class
# 3. Reduce timeout values for testing
```

### High Resource Usage

#### Symptom: Container app consuming too many resources
```bash
# CPU/Memory usage higher than expected
```

**Solution**:
```bash
# Check current resource usage
az containerapp show --name astra-dev-app --resource-group astra-dev-rg \
  --query "properties.template.containers[0].resources"

# Monitor usage
az monitor metrics list --resource /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/astra-dev-rg/providers/Microsoft.App/containerApps/astra-dev-app \
  --metric "CpuPercentage,MemoryPercentage"

# Adjust resource limits
kubectl patch xplatform astra-dev-platform -n astra-dev --type merge -p '{
  "spec": {
    "parameters": {
      "cpu": 0.5,
      "memory": "1Gi"
    }
  }
}'
```

## 🆘 Emergency Procedures

### Complete Platform Reset

If everything is broken and you need to start fresh:

```bash
#!/bin/bash
echo "🚨 EMERGENCY RESET - This will delete everything!"
read -p "Type 'CONFIRM' to proceed: " confirm
if [ "$confirm" != "CONFIRM" ]; then exit 1; fi

# 1. Delete all platform claims
kubectl delete xplatform --all --all-namespaces --ignore-not-found=true

# 2. Wait for Azure resources to be deleted
sleep 300

# 3. Force delete any remaining managed resources
kubectl get managedresources.pkg.crossplane.io --no-headers | awk '{print $1}' | xargs -I {} kubectl patch managedresource {} -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl delete managedresources.pkg.crossplane.io --all

# 4. Delete compositions and XRDs
kubectl delete compositions --all
kubectl delete xrd --all

# 5. Reinstall platform
./scripts/install.sh

echo "✅ Platform reset complete"
```

### Contact Support

When all else fails:

1. **Gather Information**:
   ```bash
   # Create support bundle
   kubectl cluster-info dump --namespaces crossplane-system,astra-dev,astra-staging,astra-prod --output-directory=support-bundle
   
   # Add Azure resource information
   az group list --query "[?starts_with(name, 'astra-')]" --output json > support-bundle/azure-resources.json
   
   # Compress bundle
   tar -czf astra-support-$(date +%Y%m%d-%H%M%S).tar.gz support-bundle/
   ```

2. **Include in Support Request**:
   - Platform version
   - Kubernetes cluster type and version
   - Azure subscription ID (last 4 digits)
   - Error messages and logs
   - Steps to reproduce
   - Support bundle file

3. **Create GitHub Issue** with:
   - Clear description of the problem
   - Expected vs actual behavior
   - Environment details
   - Troubleshooting steps already tried

Remember: Most issues can be resolved by carefully following the troubleshooting steps above. Take time to understand the error messages and check the basics first!