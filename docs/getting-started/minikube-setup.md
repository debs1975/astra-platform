# Minikube Setup Guide for Astra Platform

This guide provides comprehensive instructions for setting up Minikube as the local Kubernetes cluster for running Crossplane and the Astra Platform.

## 🎯 Why Minikube for Crossplane?

Minikube is the recommended local Kubernetes solution for Astra Platform because:

- ✅ **Lightweight & Fast**: Optimized for local development
- ✅ **Resource Control**: Fine-grained control over CPU, memory, and disk
- ✅ **Multi-Driver Support**: Docker, VirtualBox, Hyper-V, KVM2, etc.
- ✅ **Addons**: Built-in addons for metrics, dashboard, and more
- ✅ **Cross-Platform**: Works on macOS, Windows, and Linux
- ✅ **Easy Management**: Simple commands for start, stop, delete
- ✅ **Kubernetes Versions**: Easy to switch between K8s versions

## 📋 Prerequisites

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **CPU** | 2 cores | 4+ cores |
| **Memory** | 4 GB | 8 GB |
| **Disk** | 10 GB | 20 GB |
| **OS** | macOS 10.14+, Windows 10+, Linux | Latest versions |

### Required Software

1. **Docker** (for Docker driver)
   ```bash
   # Verify Docker is installed
   docker --version
   docker ps
   ```

2. **kubectl** (Kubernetes CLI)
   ```bash
   # Verify kubectl is installed
   kubectl version --client
   ```

## 🚀 Installation

### macOS
```bash
# Using Homebrew (Recommended)
brew install minikube

# Verify installation
minikube version
```

### Windows
```bash
# Using Chocolatey
choco install minikube

# Or using Scoop
scoop install minikube

# Or download installer from:
# https://github.com/kubernetes/minikube/releases/latest
```

### Linux (Ubuntu/Debian)
```bash
# Download and install
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verify installation
minikube version
```

### Linux (RHEL/CentOS/Fedora)
```bash
# Download and install
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verify installation
minikube version
```

## ⚙️ Configuration for Astra Platform

### Recommended Configuration

```bash
# Start Minikube with Crossplane-optimized settings
minikube start \
  --driver=docker \
  --cpus=4 \
  --memory=8192 \
  --disk-size=20g \
  --kubernetes-version=v1.28.0 \
  --container-runtime=containerd
```

### Configuration Breakdown

| Flag | Value | Purpose |
|------|-------|---------|
| `--driver` | `docker` | Use Docker as the container runtime |
| `--cpus` | `4` | Allocate 4 CPU cores for the cluster |
| `--memory` | `8192` | Allocate 8GB of RAM |
| `--disk-size` | `20g` | Allocate 20GB of disk space |
| `--kubernetes-version` | `v1.28.0` | Specify Kubernetes version |
| `--container-runtime` | `containerd` | Use containerd runtime |

### Alternative Drivers

#### VirtualBox (if Docker not available)
```bash
minikube start --driver=virtualbox --cpus=4 --memory=8192
```

#### HyperKit (macOS)
```bash
minikube start --driver=hyperkit --cpus=4 --memory=8192
```

#### Hyper-V (Windows)
```bash
# Run as Administrator
minikube start --driver=hyperv --cpus=4 --memory=8192
```

#### KVM2 (Linux)
```bash
# Install KVM2 driver first
curl -LO https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-kvm2
sudo install docker-machine-driver-kvm2 /usr/local/bin/

# Start Minikube
minikube start --driver=kvm2 --cpus=4 --memory=8192
```

## 🔧 Essential Minikube Commands

### Cluster Management
```bash
# Start the cluster
minikube start

# Stop the cluster (keeps state)
minikube stop

# Delete the cluster
minikube delete

# Check cluster status
minikube status

# View cluster info
kubectl cluster-info

# Get cluster IP
minikube ip
```

### Resource Management
```bash
# Check resource usage
minikube status

# SSH into the node
minikube ssh

# View logs
minikube logs

# View dashboard
minikube dashboard
```

### Addons
```bash
# List available addons
minikube addons list

# Enable metrics-server (recommended for Crossplane)
minikube addons enable metrics-server

# Enable dashboard
minikube addons enable dashboard

# Enable ingress (if needed)
minikube addons enable ingress

# Disable an addon
minikube addons disable <addon-name>
```

## 📊 Monitoring & Troubleshooting

### Check Cluster Health
```bash
# Verify nodes are ready
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Check all namespaces
kubectl get pods --all-namespaces

# Describe node details
kubectl describe node minikube
```

### Resource Monitoring
```bash
# Check resource usage with metrics-server
kubectl top nodes
kubectl top pods --all-namespaces

# View Minikube dashboard
minikube dashboard
```

### Common Issues

#### Issue: Minikube won't start
```bash
# Delete and recreate cluster
minikube delete
minikube start --driver=docker --cpus=4 --memory=8192

# Check Docker is running
docker ps

# Check logs
minikube logs
```

#### Issue: Insufficient resources
```bash
# Stop Minikube
minikube stop

# Delete and increase resources
minikube delete
minikube start --cpus=6 --memory=12288 --disk-size=30g
```

#### Issue: kubectl not connecting
```bash
# Set kubectl context
kubectl config use-context minikube

# Verify context
kubectl config current-context

# Update kubeconfig
minikube update-context
```

#### Issue: Slow performance
```bash
# Check system resources
minikube status

# Increase allocated resources
minikube stop
minikube delete
minikube start --cpus=6 --memory=12288

# Or change driver
minikube start --driver=virtualbox --cpus=4 --memory=8192
```

## 🎯 Astra Platform Specific Setup

### 1. Start Minikube for Astra
```bash
# Start with recommended settings
minikube start \
  --driver=docker \
  --cpus=4 \
  --memory=8192 \
  --disk-size=20g

# Enable required addons
minikube addons enable metrics-server

# Verify cluster is ready
kubectl get nodes
kubectl cluster-info
```

### 2. Install Crossplane
```bash
# Run the Astra Platform installation script
cd astra-platform
./scripts/install.sh
```

### 3. Verify Installation
```bash
# Check Crossplane is running
kubectl get pods -n crossplane-system

# Check XRDs are registered
kubectl get xrd

# Check Azure provider
kubectl get providers
```

### 4. Deploy Platform
```bash
# Deploy to development environment
./scripts/deploy.sh dev --wait

# Check platform status
kubectl get xplatform -n astra-dev
```

## 💡 Best Practices

### Performance Optimization
1. **Allocate sufficient resources**: Use at least 4 CPUs and 8GB RAM
2. **Use Docker driver**: Fastest and most reliable on most systems
3. **Enable metrics-server**: For resource monitoring
4. **Clean up regularly**: Delete unused clusters to free resources

### Development Workflow
```bash
# Start your day
minikube start
kubectl config use-context minikube

# Do your work...
kubectl get pods -n crossplane-system
./scripts/deploy.sh dev

# End your day (optional)
minikube stop  # Saves state, quick restart tomorrow
```

### Cleanup
```bash
# Stop cluster (keeps state)
minikube stop

# Delete cluster (removes everything)
minikube delete

# Delete all Minikube profiles
minikube delete --all

# Remove Minikube entirely
# macOS/Linux
rm -rf ~/.minikube

# Windows
Remove-Item -Path $env:USERPROFILE\.minikube -Recurse -Force
```

## 🔄 Multiple Clusters

Minikube supports multiple cluster profiles:

```bash
# Create a development cluster
minikube start --profile dev

# Create a testing cluster
minikube start --profile test

# List all profiles
minikube profile list

# Switch between profiles
minikube profile dev
kubectl config use-context dev

# Delete a specific profile
minikube delete --profile test
```

## 📚 Additional Resources

- [Minikube Official Documentation](https://minikube.sigs.k8s.io/docs/)
- [Minikube Drivers](https://minikube.sigs.k8s.io/docs/drivers/)
- [Minikube Addons](https://minikube.sigs.k8s.io/docs/commands/addons/)
- [Crossplane Documentation](https://docs.crossplane.io/)
- [Astra Platform Documentation](../README.md)

## 🆘 Getting Help

If you encounter issues:

1. **Check Minikube logs**: `minikube logs`
2. **Check Minikube status**: `minikube status`
3. **Try recreating cluster**: `minikube delete && minikube start`
4. **Check system resources**: Ensure Docker has enough resources allocated
5. **Review documentation**: [Troubleshooting Guide](../troubleshooting/debugging.md)

---

**🎉 Ready to Go!** Your Minikube cluster is now configured for Astra Platform development!

Next Steps:
1. [Run Installation Script](initial-setup.md#step-5-install-crossplane-and-azure-provider)
2. [Deploy Your First Environment](quick-start.md)
3. [Start Developing](../development/development-setup.md)
