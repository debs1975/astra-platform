# Astra Platform Setup - Minikube Primary Configuration

## Overview
The Astra Platform uses **Minikube** as the primary local Kubernetes environment for running Crossplane and deploying Azure Container Apps infrastructure.

## Why Minikube?

### Key Advantages
- ✅ **Better Resource Management**: Fine-grained control over CPU, memory, and disk allocation
- ✅ **Built-in Addons**: metrics-server, dashboard, ingress controller ready to use
- ✅ **Multiple Driver Support**: Docker, VirtualBox, HyperKit, Hyper-V, KVM2
- ✅ **Easy Management**: Simple start/stop/delete commands with state preservation
- ✅ **Cross-Platform**: Consistent experience across macOS, Windows, and Linux
- ✅ **Mature Ecosystem**: Well-tested and widely adopted in Kubernetes development
- ✅ **Crossplane Optimized**: Recommended for Crossplane development workflows

## Quick Start with Minikube

### 1. Install Minikube

**macOS:**
```bash
brew install minikube
```

**Windows (PowerShell as Administrator):**
```powershell
choco install minikube
```

**Linux:**
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### 2. Start Minikube

**Recommended Configuration for Astra Platform:**
```bash
minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=20g
```

**Resource Recommendations:**

| Use Case | CPUs | Memory | Disk | Command |
|----------|------|--------|------|---------|
| **Minimal** | 2 | 4 GB | 10 GB | `minikube start --cpus=2 --memory=4096 --disk-size=10g` |
| **Recommended** | 4 | 8 GB | 20 GB | `minikube start --cpus=4 --memory=8192 --disk-size=20g` |
| **High Performance** | 6 | 12 GB | 30 GB | `minikube start --cpus=6 --memory=12288 --disk-size=30g` |

### 3. Verify Installation

```bash
# Check cluster status
minikube status

# View cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes

# View current context
kubectl config current-context
# Should output: minikube
```

### 4. Enable Recommended Addons

```bash
# Enable metrics server for resource monitoring
minikube addons enable metrics-server

# Enable dashboard for visual management (optional)
minikube addons enable dashboard

# List all available addons
minikube addons list
```

## Driver Options

### Docker Driver (Default - Recommended)
```bash
minikube start --driver=docker --cpus=4 --memory=8192
```
- **Pros**: Fast, cross-platform, no additional hypervisor needed
- **Cons**: Requires Docker Desktop
- **Best for**: Most users, CI/CD pipelines

### HyperKit Driver (macOS Native)
```bash
minikube start --driver=hyperkit --cpus=4 --memory=8192
```
- **Pros**: Native macOS virtualization, no Docker needed
- **Cons**: macOS only
- **Best for**: macOS users who don't need Docker

### Hyper-V Driver (Windows Native)
```bash
minikube start --driver=hyperv --cpus=4 --memory=8192
```
- **Pros**: Native Windows virtualization
- **Cons**: Requires Administrator, Windows Pro/Enterprise
- **Best for**: Windows users with Hyper-V enabled

### VirtualBox Driver (Cross-Platform)
```bash
minikube start --driver=virtualbox --cpus=4 --memory=8192
```
- **Pros**: Works on all platforms
- **Cons**: Requires VirtualBox installation
- **Best for**: Environments without Docker or native hypervisors

### KVM2 Driver (Linux)
```bash
minikube start --driver=kvm2 --cpus=4 --memory=8192
```
- **Pros**: Native Linux virtualization, excellent performance
- **Cons**: Linux only, requires KVM setup
- **Best for**: Linux users with KVM

## Essential Minikube Commands

### Cluster Management
```bash
# Start cluster
minikube start

# Stop cluster (preserves state)
minikube stop

# Pause cluster (faster than stop)
minikube pause

# Unpause cluster
minikube unpause

# Delete cluster
minikube delete

# Delete all clusters
minikube delete --all
```

### Cluster Information
```bash
# Check status
minikube status

# Get cluster IP
minikube ip

# View dashboard
minikube dashboard

# SSH into node
minikube ssh

# View logs
minikube logs
```

### Resource Management
```bash
# View resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Scale resources (requires restart)
minikube delete
minikube start --cpus=6 --memory=16384
```

### Addon Management
```bash
# List addons
minikube addons list

# Enable addon
minikube addons enable <addon-name>

# Disable addon
minikube addons disable <addon-name>

# Useful addons for Astra Platform
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable ingress
```

## Minikube Profiles (Multiple Clusters)

### Create Named Profiles
```bash
# Create dev profile
minikube start -p astra-dev --cpus=2 --memory=4096

# Create staging profile
minikube start -p astra-staging --cpus=4 --memory=8192

# Create prod-sim profile
minikube start -p astra-prod --cpus=6 --memory=12288

# List profiles
minikube profile list

# Switch profile
minikube profile astra-dev

# Delete specific profile
minikube delete -p astra-dev
```

## Troubleshooting

### Cluster Won't Start
```bash
# Check Docker is running
docker info

# View detailed logs
minikube start --alsologtostderr -v=7

# Try different driver
minikube start --driver=virtualbox

# Clean start
minikube delete
minikube start --driver=docker --cpus=4 --memory=8192
```

### Performance Issues
```bash
# Check resource allocation
minikube config view

# Increase resources
minikube delete
minikube start --cpus=6 --memory=12288 --disk-size=30g

# Check resource usage
kubectl top nodes
```

### Networking Issues
```bash
# Check cluster IP
minikube ip

# Test connectivity
minikube ssh
# Inside SSH: ping 8.8.8.8

# Restart network
minikube ssh
# Inside SSH: sudo systemctl restart networking
```

### Addon Issues
```bash
# View addon status
minikube addons list

# Disable and re-enable
minikube addons disable <addon-name>
minikube addons enable <addon-name>

# Check addon pods
kubectl get pods -n kube-system
```

## Best Practices for Astra Platform

### 1. Resource Allocation
- **Development**: 4 CPUs, 8 GB RAM minimum
- **Testing**: Include extra 2 GB RAM for test workloads
- **Multiple environments**: Use profiles with appropriate resources

### 2. Persistence
- Always use `minikube stop` instead of delete to preserve cluster state
- Use persistent volumes for important data
- Regular backups of cluster configurations

### 3. Performance Optimization
```bash
# Use Docker driver for best performance
minikube start --driver=docker

# Enable caching
minikube start --cache-images

# Use containerd runtime
minikube start --container-runtime=containerd
```

### 4. Development Workflow
```bash
# Morning: Start cluster
minikube start

# Work: Deploy and test
kubectl apply -k overlays/dev

# Evening: Stop cluster (preserves state)
minikube stop

# Next day: Resume quickly
minikube start
```

### 5. Cleanup and Maintenance
```bash
# Weekly: Clean up unused images
minikube ssh docker system prune -af

# Monthly: Recreate cluster for fresh start
minikube delete
minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=20g
```

## Integration with Astra Platform

### Installation Flow
```bash
# 1. Start Minikube
minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=20g

# 2. Install Crossplane
./scripts/install.sh

# 3. Deploy environment
./scripts/deploy.sh dev --wait

# 4. Verify deployment
kubectl get xplatform -n astra-dev

# 5. Get application URL
kubectl get xplatform astra-dev-platform -n astra-dev -o jsonpath='{.status.applicationUrl}'
```

### kubectl Context
All Astra Platform scripts automatically work with the `minikube` context. No manual context switching required.

### Monitoring and Debugging
```bash
# View Crossplane pods
kubectl get pods -n crossplane-system

# View Minikube dashboard
minikube dashboard

# Monitor resources
watch kubectl get xplatform --all-namespaces

# Check resource usage
kubectl top nodes
kubectl top pods -n crossplane-system
```

## Configuration File

Save common settings in Minikube config:

```bash
# Set default driver
minikube config set driver docker

# Set default resources
minikube config set cpus 4
minikube config set memory 8192
minikube config set disk-size 20g

# View configuration
minikube config view

# Unset configuration
minikube config unset <property>
```

## Summary

Minikube provides the ideal local Kubernetes environment for the Astra Platform with:

- ✅ Simple installation and setup
- ✅ Flexible resource management
- ✅ Cross-platform compatibility
- ✅ Excellent Crossplane support
- ✅ Rich addon ecosystem
- ✅ Easy troubleshooting
- ✅ Production-like experience

For detailed setup instructions, see:
- [Minikube Setup Guide](../docs/getting-started/minikube-setup.md)
- [Prerequisites](../docs/getting-started/prerequisites.md)
- [Initial Setup](../docs/getting-started/initial-setup.md)
