# Contributing Guide

Welcome to the Astra Platform! We're excited that you're interested in contributing. This guide will help you get started with contributing to the project.

## 🎯 Ways to Contribute

- **🐛 Bug Reports**: Report issues and bugs
- **✨ Feature Requests**: Suggest new features or improvements
- **📖 Documentation**: Improve documentation and guides
- **💻 Code**: Contribute bug fixes and new features
- **🧪 Testing**: Help test new features and report feedback
- **🎨 UX/Design**: Improve user experience and interface design

## 📋 Before You Start

### Prerequisites
- Review the [Prerequisites Guide](getting-started/prerequisites.md)
- Set up your development environment following [Development Setup](development-setup.md)
- Read through the [Platform Architecture](../architecture/platform-architecture.md)
- Familiarize yourself with Crossplane concepts

### Code of Conduct
Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md). We're committed to creating a welcoming and inclusive environment.

## 🚀 Getting Started

### 1. Fork and Clone
```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/your-username/astra-platform.git
cd astra-platform

# Add upstream remote
git remote add upstream https://github.com/original-org/astra-platform.git
```

### 2. Set Up Development Environment
```bash
# Install the platform locally
./scripts/install.sh

# Verify setup works
./scripts/deploy.sh dev --dry-run
```

### 3. Create a Branch
```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Or a bug fix branch
git checkout -b fix/issue-number-description
```

## 🏗️ Development Workflow

### 1. Making Changes

#### For Infrastructure Changes (XRDs/Compositions)
```bash
# Edit XRD definition
vim packages/componentname/definition.yaml

# Edit corresponding composition
vim packages/componentname/composition.yaml

# Test changes
kubectl apply --dry-run=client -f packages/componentname/definition.yaml
kubectl apply --dry-run=client -f packages/componentname/composition.yaml
```

#### For Script Changes
```bash
# Edit script
vim scripts/scriptname.sh

# Test script
./scripts/scriptname.sh --help
./scripts/scriptname.sh --dry-run  # if available
```

#### For Documentation Changes
```bash
# Edit documentation
vim docs/section/document.md

# Check links and formatting
# Ensure all internal links work
# Test code examples
```

### 2. Testing Your Changes

#### Validate Infrastructure Changes
```bash
# Validate XRDs and Compositions
./scripts/validate-resources.sh

# Or manually test
minikube start --driver=docker --cpus=4 --memory=8192
kubectl apply -f packages/componentname/definition.yaml
kubectl wait --for=condition=Established xrd/component.astra.platform --timeout=60s
kubectl apply -f packages/componentname/composition.yaml
```

#### Test Script Changes
```bash
# Test on multiple platforms if possible
# macOS:
./scripts/your-script.sh

# Windows (WSL):
bash ./scripts/your-script.sh

# Test error conditions
./scripts/your-script.sh --invalid-flag
```

#### Test Environment Deployment
```bash
# Deploy to dev environment
./scripts/deploy.sh dev --wait

# Verify deployment
kubectl get xplatform -n astra-dev
kubectl describe xplatform -n astra-dev

# Test application access
APP_URL=$(kubectl get xplatform astra-dev-platform -n astra-dev -o jsonpath='{.status.applicationUrl}')
curl -I "https://$APP_URL"
```

### 3. Documentation Requirements

For all changes, ensure:

#### Code Changes
- [ ] Update relevant documentation
- [ ] Add/update examples if applicable
- [ ] Update troubleshooting guides if needed

#### New Features
- [ ] Add user guide documentation
- [ ] Update architecture documentation if needed
- [ ] Add API reference documentation
- [ ] Include usage examples

#### Bug Fixes
- [ ] Update troubleshooting documentation
- [ ] Add prevention guidance if applicable

### 4. Commit Guidelines

#### Commit Message Format
```
type(scope): brief description

Detailed explanation of the change, if needed.

Closes #issue-number
```

#### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

#### Examples
```bash
git commit -m "feat(containerapp): add auto-scaling configuration support

Add minReplicas and maxReplicas parameters to Container App XRD
to support automatic scaling based on demand.

Closes #123"

git commit -m "fix(scripts): handle missing Azure CLI in install script

Add check for Azure CLI installation and provide helpful error
message with installation instructions.

Closes #456"

git commit -m "docs(troubleshooting): add common deployment issues

Add section covering Container App deployment failures and
their resolutions based on user feedback.

Closes #789"
```

## 🧪 Testing Guidelines

### Local Testing
```bash
# 1. Validate all YAML files
find . -name "*.yaml" -o -name "*.yml" | xargs yamllint

# 2. Test Crossplane resources
./scripts/validate-crossplane.sh

# 3. Test script functionality
./scripts/test-scripts.sh

# 4. End-to-end test
./scripts/e2e-test.sh
```

### CI/CD Testing
Our GitHub Actions will automatically:
- Validate YAML syntax
- Test Crossplane resource definitions
- Run security scans
- Test cross-platform compatibility

Ensure your changes pass all CI checks before requesting review.

## 📝 Pull Request Process

### 1. Prepare Your PR
```bash
# Ensure your branch is up-to-date
git fetch upstream
git rebase upstream/main

# Run final tests
./scripts/validate-all.sh

# Push your changes
git push origin your-branch-name
```

### 2. Create Pull Request
1. **Go to GitHub**: Open a pull request from your fork
2. **Fill Template**: Use the provided PR template
3. **Add Details**: Include:
   - Clear description of changes
   - Testing performed
   - Related issues
   - Screenshots (if UI changes)

### 3. PR Template
```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Performance improvement

## Testing
- [ ] Local testing completed
- [ ] CI/CD tests pass
- [ ] Cross-platform testing (if applicable)
- [ ] Documentation updated

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added to complex code
- [ ] Documentation updated
- [ ] No breaking changes (or marked as such)

Closes #issue-number
```

### 4. Review Process
1. **Automated Checks**: CI/CD must pass
2. **Code Review**: At least one maintainer review required
3. **Testing**: Reviewer will test changes
4. **Documentation**: Documentation review if applicable
5. **Approval**: Maintainer approval required for merge

## 🏷️ Issue Guidelines

### Bug Reports
Use the bug report template and include:
- **Environment**: OS, Kubernetes version, Azure region
- **Steps to Reproduce**: Clear, numbered steps
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Logs**: Relevant error messages and logs
- **Screenshots**: If applicable

### Feature Requests
Use the feature request template and include:
- **Problem**: What problem does this solve?
- **Solution**: Proposed solution
- **Alternatives**: Alternative solutions considered
- **Examples**: Usage examples or mockups

### Labels
We use these labels to categorize issues:
- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Documentation improvements
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention needed
- `priority/high`: High priority
- `priority/low`: Low priority

## 🎨 Code Style Guidelines

### YAML Files
```yaml
# Use 2-space indentation
apiVersion: astra.platform/v1alpha1
kind: XComponentName
metadata:
  name: component-name
  labels:
    component: name
spec:
  # Group related fields
  parameters:
    # Use meaningful names
    namingPrefix: ""
    location: "Central India"
    
    # Document complex fields
    resourceConfiguration:
      # CPU allocation in cores
      cpu: 0.25
      # Memory allocation in Gi
      memory: "0.5Gi"
```

### Shell Scripts
```bash
#!/bin/bash
# Always use strict mode
set -euo pipefail

# Document functions
# Creates Azure service principal with contributor role
create_service_principal() {
    local sp_name="$1"
    local scope="$2"
    
    # Implementation
}

# Use meaningful variable names
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP_NAME="astra-dev-rg"

# Error handling
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi
```

### Documentation
- Use clear, concise language
- Include working code examples
- Test all code snippets
- Use consistent formatting
- Add table of contents for long documents

## 🚀 Advanced Contributions

### Adding New Azure Services
1. **Create XRD**: Define the API in `packages/servicename/definition.yaml`
2. **Create Composition**: Implement in `packages/servicename/composition.yaml`
3. **Update Platform**: Add to platform composition
4. **Add Tests**: Create validation tests
5. **Documentation**: Add usage guides

### Extending Environments
1. **Create Overlay**: Add new environment in `overlays/`
2. **Update Scripts**: Modify deployment scripts
3. **Add CI/CD**: Update workflow files
4. **Documentation**: Update environment guides

### New Automation Scripts
1. **Follow Conventions**: Use existing script patterns
2. **Cross-Platform**: Support macOS, Windows, Linux
3. **Error Handling**: Comprehensive error handling
4. **Help Text**: Include `--help` option
5. **Testing**: Add to test suite

## 🏆 Recognition

Contributors are recognized in:
- **Release Notes**: Major contributions highlighted
- **Contributors File**: All contributors listed
- **Documentation**: Attribution in relevant sections

## 📞 Getting Help

- **💬 Discussions**: Use GitHub Discussions for questions
- **📧 Email**: Contact maintainers directly for sensitive issues
- **📖 Documentation**: Check existing documentation first
- **🐛 Issues**: Create an issue for bugs or feature requests

## 📚 Resources

- [Crossplane Documentation](https://crossplane.io/docs/)
- [Azure Provider Documentation](https://marketplace.upbound.io/providers/upbound/provider-azure/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)

Thank you for contributing to the Astra Platform! 🎉