# Application Deployment Guide

Learn how to deploy your applications on the Astra Platform using Azure Container Apps with integrated Azure services.

## 📋 Prerequisites

Before deploying applications, ensure:
- ✅ Astra Platform is deployed ([Platform Deployment Guide](platform-deployment.md))
- ✅ Container image is available in a registry
- ✅ Application configuration is ready
- ✅ Required secrets are prepared

## 🎯 Deployment Overview

Application deployment on Astra Platform involves:

1. **Container Image Preparation** - Build and push to Azure Container Registry
2. **Configuration Setup** - Environment variables and secrets
3. **Platform Claim Creation** - Deploy using Crossplane
4. **Service Configuration** - Ingress, scaling, and networking
5. **Verification and Testing** - Ensure application is running correctly

## 🏗️ Application Architecture

```mermaid
graph TB
    subgraph "User Traffic"
        Internet[Internet Users]
        DNS[Azure DNS]
    end
    
    subgraph "Container Apps Platform"
        Ingress[Ingress Controller<br/>HTTPS/TLS]
        LB[Load Balancer<br/>Auto-scaling]
        
        subgraph "Application Instances"
            App1[Container App<br/>Instance 1]
            App2[Container App<br/>Instance 2]
            App3[Container App<br/>Instance N]
        end
    end
    
    subgraph "Identity & Security"
        MI[Managed Identity<br/>Passwordless Auth]
        KV[Key Vault<br/>API Keys, Passwords]
    end
    
    subgraph "Container Infrastructure"
        ACR[Container Registry<br/>Docker Images]
        LAW[Log Analytics<br/>Metrics & Logs]
    end
    
    subgraph "Data Layer"
        SA[Storage Account<br/>Blob Storage]
        BC[Blob Container<br/>Application Data]
    end
    
    Internet --> DNS
    DNS --> Ingress
    Ingress --> LB
    LB --> App1
    LB --> App2
    LB --> App3
    
    ACR -.Image Pull.-> App1
    ACR -.Image Pull.-> App2
    ACR -.Image Pull.-> App3
    
    App1 --> MI
    App2 --> MI
    App3 --> MI
    
    MI -.Get Secrets.-> KV
    MI -.Read/Write.-> SA
    SA --> BC
    
    App1 -.Logs.-> LAW
    App2 -.Logs.-> LAW
    App3 -.Logs.-> LAW
    
    style Internet fill:#E1E1E1,color:#000
    style Ingress fill:#0078D4,color:#fff
    style App1 fill:#8661C5,color:#fff
    style App2 fill:#8661C5,color:#fff
    style App3 fill:#8661C5,color:#fff
    style MI fill:#FFB900,color:#000
    style KV fill:#E74856,color:#fff
```

## 🔄 Application Runtime Data Flow

```mermaid
sequenceDiagram
    participant User
    participant Ingress
    participant App as Container App
    participant MI as Managed Identity
    participant KV as Key Vault
    participant SA as Storage Account
    participant ACR as Container Registry
    participant LAW as Log Analytics
    
    Note over User,LAW: Application Startup
    App->>MI: Request Identity Token
    MI-->>App: Token Issued
    
    App->>ACR: Pull Container Image
    ACR-->>App: Image Downloaded
    
    App->>KV: Get Database Password
    KV-->>App: Secret Retrieved
    
    App->>SA: Initialize Storage Connection
    SA-->>App: Connection Established
    
    Note over User,LAW: User Request Flow
    User->>Ingress: HTTPS Request
    Ingress->>App: Route to Instance
    
    App->>KV: Get API Key (cached)
    KV-->>App: API Key
    
    App->>SA: Read/Write Data
    SA-->>App: Data Retrieved
    
    App->>App: Process Request
    App-->>Ingress: Response
    Ingress-->>User: HTTPS Response
    
    Note over User,LAW: Monitoring & Logging
    App->>LAW: Send Application Logs
    App->>LAW: Send Performance Metrics
    LAW-->>LAW: Aggregate & Store
```

## � Application Deployment Workflow

```mermaid
graph LR
    subgraph "Development"
        Code[Application Code]
        Docker[Dockerfile]
        Build[Docker Build]
    end
    
    subgraph "Azure Container Registry"
        ACR[Container Registry<br/>astradevacr]
        Image[Container Image<br/>myapp:v1.0.0]
    end
    
    subgraph "Kubernetes"
        Claim[Platform Claim<br/>XPlatform]
        Crossplane[Crossplane<br/>Reconciliation]
    end
    
    subgraph "Azure Resources"
        RG[Resource Group]
        MI[Managed Identity]
        KV[Key Vault<br/>Secrets]
        SA[Storage Account<br/>Data]
        CA[Container App<br/>Running App]
    end
    
    Code --> Docker
    Docker --> Build
    Build --> ACR
    ACR --> Image
    
    Claim --> Crossplane
    Crossplane --> RG
    RG --> MI
    MI --> KV
    MI --> SA
    MI --> CA
    
    Image -.Pulls Image.-> CA
    KV -.Injects Secrets.-> CA
    SA -.Mounts Storage.-> CA
    
    style Build fill:#4B9CD3,color:#fff
    style ACR fill:#0078D4,color:#fff
    style Crossplane fill:#326CE5,color:#fff
    style CA fill:#8661C5,color:#fff
```

## 🔄 Deployment Lifecycle

```mermaid
stateDiagram-v2
    [*] --> BuildImage: Developer commits code
    BuildImage --> PushToACR: docker build & tag
    PushToACR --> CreateSecrets: Store in Key Vault
    CreateSecrets --> DeployPlatform: kubectl apply
    DeployPlatform --> Provisioning: Crossplane creates resources
    Provisioning --> ConfigureApp: Set environment variables
    ConfigureApp --> DeployApp: Container App starts
    DeployApp --> HealthCheck: Verify /health endpoint
    HealthCheck --> Running: All checks pass
    HealthCheck --> Failed: Checks fail
    Failed --> Troubleshoot: View logs
    Troubleshoot --> ConfigureApp: Fix and redeploy
    Running --> UpdateImage: New version
    UpdateImage --> BuildImage
    Running --> ScaleApp: Load increases
    ScaleApp --> Running: Auto-scale complete
    Running --> [*]: Cleanup
```

## �🚀 Step-by-Step Deployment

### Step 1: Prepare Container Image

#### 1.1 Build Application Image
```bash
# Example Node.js application
cat <<EOF > Dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Run application
CMD ["npm", "start"]
EOF

# Build image
docker build -t my-app:v1.0.0 .
```

#### 1.2 Push to Azure Container Registry
```bash
# Set environment variables
ENVIRONMENT="dev"  # or staging, prod
ACR_NAME="astra${ENVIRONMENT}acr"
IMAGE_NAME="my-app"
VERSION="v1.0.0"

# Login to ACR
az acr login --name "$ACR_NAME"

# Tag image
docker tag "$IMAGE_NAME:$VERSION" "$ACR_NAME.azurecr.io/$IMAGE_NAME:$VERSION"

# Push image
docker push "$ACR_NAME.azurecr.io/$IMAGE_NAME:$VERSION"

# Verify image
az acr repository show --name "$ACR_NAME" --image "$IMAGE_NAME:$VERSION"
```

### Step 2: Prepare Application Configuration

#### 2.1 Create Environment Variables Configuration
```yaml
# config/my-app-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-config
  namespace: astra-dev
data:
  NODE_ENV: "production"
  PORT: "3000"
  LOG_LEVEL: "info"
  ENABLE_METRICS: "true"
  DATABASE_URL: "postgresql://user:pass@host:5432/db"
```

#### 2.2 Create Secrets in Key Vault
```bash
# Set Key Vault name
KEY_VAULT_NAME="astra-${ENVIRONMENT}-kv"

# Store database password
az keyvault secret set \
  --vault-name "$KEY_VAULT_NAME" \
  --name "database-password" \
  --value "your-secure-password"

# Store API keys
az keyvault secret set \
  --vault-name "$KEY_VAULT_NAME" \
  --name "api-key" \
  --value "your-api-key"

# Store JWT secret
az keyvault secret set \
  --vault-name "$KEY_VAULT_NAME" \
  --name "jwt-secret" \
  --value "your-jwt-secret"
```

### Step 3: Deploy Application

#### 3.1 Create Application Platform Claim
```yaml
# my-app-platform.yaml
apiVersion: astra.platform/v1alpha1
kind: XPlatform
metadata:
  name: my-app-platform
  namespace: astra-dev
spec:
  # Environment configuration
  environment: "dev"
  location: "Central India"
  namingPrefix: "myapp"
  
  # Resource tags
  tags:
    Application: "my-application"
    Environment: "dev"
    Team: "development"
    CostCenter: "engineering"
    
  # Container application configuration
  containerApp:
    # Container image from ACR
    image: "astradevacr.azurecr.io/my-app:v1.0.0"
    
    # Resource allocation
    cpu: 0.5
    memory: "1Gi"
    
    # Scaling configuration
    minReplicas: 2
    maxReplicas: 10
    
    # Environment variables
    environmentVariables:
      # From ConfigMap
      - name: "NODE_ENV"
        value: "production"
      - name: "PORT"
        value: "3000"
      - name: "LOG_LEVEL"
        value: "info"
        
      # From Key Vault secrets
      - name: "DATABASE_PASSWORD"
        secretRef: "database-password"
      - name: "API_KEY"
        secretRef: "api-key"
      - name: "JWT_SECRET"
        secretRef: "jwt-secret"
    
    # Ingress configuration
    ingress:
      external: true
      targetPort: 3000
      allowInsecure: false
      
  # Optional: Enable additional services
  storage:
    enableStorage: true
    accountType: "Standard_LRS"
    
  # Optional: Custom Key Vault configuration
  security:
    enableKeyVault: true
    keyVaultAccessPolicies:
      - tenantId: "your-tenant-id"
        objectId: "your-app-identity-object-id"
        permissions:
          secrets: ["get", "list"]
```

#### 3.2 Deploy Application
```bash
# Apply the platform claim
kubectl apply -f my-app-platform.yaml

# Monitor deployment
kubectl get xplatform my-app-platform -n astra-dev -w

# Check deployment status
kubectl describe xplatform my-app-platform -n astra-dev
```

### Step 4: Monitor Deployment Progress

#### 4.1 Watch Platform Creation
```bash
# Monitor all resources in namespace
watch -n 5 'kubectl get all,xplatform -n astra-dev'

# Check platform conditions
kubectl get xplatform my-app-platform -n astra-dev -o jsonpath='{.status.conditions[*].type}{"\n"}{.status.conditions[*].status}{"\n"}'

# View deployment events
kubectl get events -n astra-dev --sort-by='.lastTimestamp'
```

#### 4.2 Monitor Azure Resources
```bash
# Set resource group
RESOURCE_GROUP="myapp-dev-rg"

# Monitor resource creation
watch -n 10 'az resource list --resource-group "'$RESOURCE_GROUP'" --output table'

# Check container app status
az containerapp show --name "myapp-dev-app" --resource-group "$RESOURCE_GROUP" --query "properties.provisioningState"
```

## ✅ Verification and Testing

### 1. Application Accessibility
```bash
# Get application URL
APP_URL=$(kubectl get xplatform my-app-platform -n astra-dev -o jsonpath='{.status.components.containerApp.applicationUrl}')

echo "Application URL: $APP_URL"

# Test application
curl -f "$APP_URL/health"

# Test with verbose output
curl -v "$APP_URL"

# Load test (optional)
for i in {1..10}; do
  curl -s "$APP_URL" > /dev/null && echo "Request $i: Success" || echo "Request $i: Failed"
done
```

### 2. Application Logs
```bash
# View container app logs
az containerapp logs show \
  --name "myapp-dev-app" \
  --resource-group "$RESOURCE_GROUP" \
  --follow

# View recent logs
az containerapp logs show \
  --name "myapp-dev-app" \
  --resource-group "$RESOURCE_GROUP" \
  --tail 100
```

### 3. Performance Testing
```bash
# Simple load test with curl
echo "Running load test..."
for i in {1..100}; do
  curl -s -w "%{http_code} %{time_total}\n" "$APP_URL" -o /dev/null &
done
wait

# Advanced load testing with Apache Bench (if installed)
ab -n 1000 -c 10 "$APP_URL/"

# Or with curl in parallel
echo "Testing concurrent requests..."
seq 1 50 | xargs -n1 -P10 curl -s "$APP_URL" > /dev/null
echo "Load test complete!"
```

## 🔧 Advanced Configuration

### Multi-Container Applications
```yaml
# For applications requiring multiple containers
spec:
  containerApp:
    # Main application container
    image: "astradevacr.azurecr.io/my-app:v1.0.0"
    
    # Sidecar containers (using init containers pattern)
    initContainers:
      - name: "database-migration"
        image: "astradevacr.azurecr.io/db-migrate:v1.0.0"
        command: ["npm", "run", "migrate"]
```

### Custom Health Checks
```yaml
spec:
  containerApp:
    # Health check configuration
    healthCheck:
      httpGet:
        path: "/health"
        port: 3000
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
```

### Auto-scaling Configuration
```yaml
spec:
  containerApp:
    # Advanced scaling rules
    scaling:
      minReplicas: 2
      maxReplicas: 20
      rules:
        - name: "http-scaling"
          http:
            metadata:
              concurrentRequests: "10"
        - name: "cpu-scaling"
          custom:
            type: "cpu"
            metadata:
              type: "Utilization"
              value: "70"
```

### Volume Mounts and Storage
```yaml
spec:
  # Enable storage
  storage:
    enableStorage: true
    accountType: "Standard_LRS"
    
  containerApp:
    # Volume mounts
    volumes:
      - name: "app-storage"
        storageType: "AzureFile"
        storageName: "myapp-dev-storage"
    
    # Mount points
    volumeMounts:
      - name: "app-storage"
        mountPath: "/app/data"
```

## 🔄 Application Updates

### Rolling Updates
```bash
# Build new version
docker build -t my-app:v1.1.0 .

# Push to registry
docker tag my-app:v1.1.0 "$ACR_NAME.azurecr.io/my-app:v1.1.0"
docker push "$ACR_NAME.azurecr.io/my-app:v1.1.0"

# Update platform claim
kubectl patch xplatform my-app-platform -n astra-dev --type='merge' -p='{"spec":{"containerApp":{"image":"'$ACR_NAME'.azurecr.io/my-app:v1.1.0"}}}'

# Monitor update
kubectl get xplatform my-app-platform -n astra-dev -w
```

### Blue-Green Deployment
```bash
# Deploy to staging first
kubectl apply -f my-app-platform.yaml -n astra-staging

# Test staging
STAGING_URL=$(kubectl get xplatform my-app-platform -n astra-staging -o jsonpath='{.status.components.containerApp.applicationUrl}')
curl -f "$STAGING_URL/health"

# If tests pass, deploy to production
kubectl apply -f my-app-platform.yaml -n astra-prod
```

### Configuration Updates
```bash
# Update environment variables
kubectl patch xplatform my-app-platform -n astra-dev --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/containerApp/environmentVariables/-",
    "value": {
      "name": "NEW_FEATURE_FLAG",
      "value": "enabled"
    }
  }
]'

# Update secrets in Key Vault
az keyvault secret set \
  --vault-name "$KEY_VAULT_NAME" \
  --name "api-key" \
  --value "new-api-key-value"

# Restart application to pick up new secrets
kubectl annotate xplatform my-app-platform -n astra-dev app.kubernetes.io/restartedAt="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

## 📊 Monitoring and Observability

### Application Metrics
```bash
# Enable Application Insights (if configured)
az monitor app-insights component show \
  --app "myapp-dev-insights" \
  --resource-group "$RESOURCE_GROUP"

# View metrics
az monitor metrics list \
  --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.App/containerApps/myapp-dev-app" \
  --metric "Requests"
```

### Log Aggregation
```bash
# Stream logs in real-time
az containerapp logs show \
  --name "myapp-dev-app" \
  --resource-group "$RESOURCE_GROUP" \
  --follow \
  --format json

# Query specific time range
az containerapp logs show \
  --name "myapp-dev-app" \
  --resource-group "$RESOURCE_GROUP" \
  --since "2024-01-15T10:00:00Z"
```

### Custom Dashboards
```bash
# Create custom Grafana dashboard (if Grafana is available)
curl -X POST http://grafana-url/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @my-app-dashboard.json
```

## 🛠️ Troubleshooting

### Common Issues

#### Image Pull Errors
```bash
# Check ACR permissions
az acr check-health --name "$ACR_NAME"

# Verify image exists
az acr repository show --name "$ACR_NAME" --image "my-app:v1.0.0"

# Check managed identity permissions
az role assignment list --assignee "$(kubectl get xplatform my-app-platform -n astra-dev -o jsonpath='{.status.components.managedIdentity.principalId}')"
```

#### Application Not Starting
```bash
# Check container app status
az containerapp show --name "myapp-dev-app" --resource-group "$RESOURCE_GROUP" --query "properties.provisioningState"

# View detailed logs
az containerapp logs show --name "myapp-dev-app" --resource-group "$RESOURCE_GROUP" --tail 200

# Check environment variables
az containerapp show --name "myapp-dev-app" --resource-group "$RESOURCE_GROUP" --query "properties.template.containers[0].env"
```

#### Networking Issues
```bash
# Test internal connectivity
kubectl run test-pod --image=busybox --restart=Never -it --rm -- sh

# From inside test pod:
# nslookup myapp-dev-app
# wget -qO- http://myapp-dev-app:3000/health

# Check ingress configuration
az containerapp ingress show --name "myapp-dev-app" --resource-group "$RESOURCE_GROUP"
```

### Debug Mode
```bash
# Enable debug logging for the application
kubectl patch xplatform my-app-platform -n astra-dev --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/containerApp/environmentVariables/-",
    "value": {
      "name": "LOG_LEVEL",
      "value": "debug"
    }
  }
]'
```

## 🚀 Best Practices

### Security
- Use Azure Key Vault for all secrets
- Enable managed identity for Azure service access
- Use least privilege access policies
- Regularly rotate secrets and certificates

### Performance
- Set appropriate resource limits
- Configure auto-scaling based on metrics
- Use health checks for better reliability
- Implement graceful shutdown handling

### Reliability
- Set up proper health checks
- Configure retry policies
- Implement circuit breakers
- Use multiple replicas for high availability

### Cost Optimization
- Right-size resource allocations
- Use appropriate scaling policies
- Monitor and optimize based on usage patterns
- Clean up unused resources regularly

## 📚 Next Steps

After deploying your application:

1. **[Set up Monitoring](monitoring-observability.md)** - Configure comprehensive monitoring
2. **[Configure CI/CD](../operations/cicd-setup.md)** - Automate deployments
3. **[Environment Management](environment-management.md)** - Manage multiple environments
4. **[Security Best Practices](security-best-practices.md)** - Enhance security posture

## 📞 Support

Need help with application deployment?

- Check the [Troubleshooting Guide](../troubleshooting/debugging.md)
- Review [Platform Architecture](../architecture/platform-architecture.md)
- Join our [Community Discussions](https://github.com/your-org/astra-platform/discussions)
- Contact the platform team

---

**🎉 Congratulations!** Your application is now running on the Astra Platform with enterprise-grade Azure services!