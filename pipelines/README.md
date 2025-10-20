# Azure DevOps Pipelines

This directory contains Azure DevOps pipeline definitions for the Astra Platform.

## 📚 Complete Documentation

For comprehensive CI/CD setup instructions, configuration, and troubleshooting, see:
**[docs/operations/cicd-setup.md](../docs/operations/cicd-setup.md)**

## Pipeline Files

### `azure-pipelines.yml`
The main Azure DevOps pipeline that handles the complete CI/CD workflow:

- **Validation Stage**: YAML validation, Crossplane resource validation, naming convention checks
- **Testing Stage**: Unit tests and integration tests with Azure resource lifecycle testing
- **Security Stage**: Secret detection with truffleHog, YAML security validation  
- **Build Stage**: Crossplane configuration packaging and artifact publishing
- **Deploy Stage**: Multi-environment deployment (dev → staging) with E2E testing
- **Release Stage**: Automated GitHub release creation and packaging

## Pipeline Configuration

### Triggers
- **Branch Triggers**: `main`, `develop`, `release/*`
- **Pull Request Triggers**: `main`, `develop`
- **Path Exclusions**: Documentation files (`*.md`, `docs/**`)

### Variables
- `vmImageName`: ubuntu-latest
- `crossplaneVersion`: 1.14.0
- `azureProviderVersion`: v0.36.0
- `azureLocation`: centralindia

### Prerequisites
Before using these pipelines, ensure you have:

1. **Service Connections** configured in Azure DevOps:
   - `astra-service-connection`: Azure Resource Manager connection
   - `astra-kubernetes-connection`: Kubernetes connection (optional)

2. **Variable Groups** created in Azure DevOps Library:
   - `astra-azure-credentials`: Azure authentication details
   - `astra-kubernetes-config`: Kubernetes configuration

3. **Environments** created in Azure DevOps:
   - `astra-dev`: Development environment
   - `astra-staging`: Staging environment (with approval)
   - `astra-prod`: Production environment (with security checks)

## Usage

### Setting up the Pipeline

1. **Navigate to Azure DevOps**: Go to your Azure DevOps project
2. **Create New Pipeline**: Pipelines → New pipeline
3. **Select Repository**: Choose your repository source
4. **Existing YAML File**: Select `/pipelines/azure-pipelines.yml`
5. **Save and Run**: Configure variables and run the pipeline

### Manual Pipeline Execution

You can trigger specific stages manually:

```bash
# Trigger full pipeline
# Navigate to: Pipelines → [Pipeline Name] → Run pipeline

# Trigger specific environment deployment
# Use the Deploy stage with environment parameters
```

### Branch-based Execution

- **Main Branch**: Full pipeline with deployment to dev → staging
- **Develop Branch**: Validation, testing, and dev deployment only
- **Feature Branches**: Validation and unit tests only
- **Release Branches**: Full pipeline with production deployment

## Pipeline Stages

### 1. Validate Stage
```yaml
- YAML file syntax validation
- Crossplane XRD and Composition validation
- Resource naming convention verification
```

### 2. Test Stage
```yaml
- Unit tests (always runs)
- Integration tests (main branch only)
- Test result publishing
```

### 3. Security Stage
```yaml
- Secret detection scanning
- YAML security configuration validation
- Security report publishing
```

### 4. Build Stage
```yaml
- Crossplane package creation
- Build artifact archiving
- Artifact publishing
```

### 5. Deploy Stage
```yaml
- Development environment deployment
- End-to-end testing
- Staging environment deployment (after dev success)
```

### 6. Release Stage
```yaml
- Release package creation
- GitHub release publishing (for release branches)
- Release notes generation
```

## Monitoring and Troubleshooting

### Pipeline Monitoring
- **Azure DevOps Dashboard**: View pipeline runs, success rates, and trends
- **Test Results**: Integrated test result publishing and tracking
- **Artifacts**: Build artifacts available for download and deployment

### Common Issues
- **Authentication**: Check service connection configuration
- **Variable Groups**: Ensure proper access to variable groups
- **Environment Permissions**: Verify environment access and approval settings

For detailed troubleshooting, see:
- [CI/CD Setup Guide](../docs/operations/cicd-setup.md)
- [Debugging Guide](../docs/troubleshooting/debugging.md)

### Logs and Debugging
- **Pipeline Logs**: Available in Azure DevOps pipeline run details
- **Test Logs**: Published as pipeline artifacts
- **Debug Mode**: Enable `system.debug: true` variable for detailed logging

## Security Considerations

- All sensitive variables are stored in Azure DevOps variable groups
- Service principal authentication with least privilege access
- Environment-specific access controls and approval gates
- Automatic secret scanning in every pipeline run
- Audit logging for all pipeline activities

## Performance Optimization

- Parallel job execution where possible
- Caching of dependencies and tools
- Optimized Docker builds and artifact handling
- Conditional stage execution based on changes and branches

---

## 📖 Related Documentation

- **[CI/CD Setup Guide](../docs/operations/cicd-setup.md)** - Complete pipeline setup and configuration
- **[Azure Resources Creation](../docs/operations/azure-resources-creation.md)** - Azure CLI automation
- **[Deployment Guide](../docs/user-guides/application-deployment.md)** - Application deployment
- **[Troubleshooting](../docs/troubleshooting/debugging.md)** - Debugging and troubleshooting

---

**Built with ❤️ by the Astra Platform Team**