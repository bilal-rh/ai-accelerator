# AI Accelerator - Helm Chart

A complete Helm-based solution for deploying OpenShift AI/ML platform with all necessary operators, instances, and tenant workloads. This project provides a simplified, maintainable alternative to the original Kustomize-based deployment while achieving identical functionality.

## 🚀 Overview

The AI Accelerator Helm Chart automates the deployment of:

- **Operators**: OpenShift AI (RHOAI), GitOps, Pipelines, Serverless, ServiceMesh, Authorino, GPU Operator, Node Feature Discovery
- **OpenShift AI Instances**: Data Science Cluster (DSC) and DSC Initialization (DSCI)
- **Applications**: MinIO S3-compatible storage
- **Tenant Workloads**: AI/ML namespaces, workbenches, model serving, data science pipelines, and LM evaluation labs

## 🏗️ Architecture

The deployment uses a **three-phase approach** for reliable, idempotent installations:

```
Phase 1: Operators          → Install all required operators
Phase 2: AI Instances       → Create OpenShift AI instances (DSC/DSCI)  
Phase 3: Tenant Workloads   → Deploy applications and tenant resources
```

### Chart Structure

```
ai-accelerator/
├── charts/
│   ├── openshift-gitops/           # GitOps operator and configuration
│   ├── openshift-operators/        # All operator subscriptions and instances
│   ├── cluster-configs/            # Cluster-level configurations
│   ├── applications/               # Applications (MinIO, etc.)
│   └── tenants/                    # Tenant namespaces and workloads
├── values-production.yaml          # Production deployment values
├── values-gpu.yaml                 # GPU-enabled deployment values
├── values-minimal.yaml             # Minimal deployment values
└── deploy.sh                       # Main deployment script
```

## 🚀 Quick Start

### Prerequisites

- OpenShift 4.12+ cluster with cluster-admin access
- Helm 3.8+ installed
- `oc` CLI configured and logged in

### Basic Deployment

```bash
# Clone the repository
git clone <repository-url>
cd ai-accelerator-helm

# Deploy with production configuration
./deploy.sh values-production.yaml

# Or use the default (production) configuration
./deploy.sh
```

### GPU-Enabled Deployment

```bash
# Deploy with GPU support
./deploy.sh values-gpu.yaml
```

### Minimal Deployment

```bash
# Deploy minimal configuration for testing
./deploy.sh values-minimal.yaml
```

## 📋 Deployment Options

### Values Files

| File | Description | Use Case |
|------|-------------|----------|
| `values-production.yaml` | Full production setup with all operators and tenant workloads | Production environments |
| `values-gpu.yaml` | GPU-optimized configuration with GPU operators and resources | GPU-enabled clusters |
| `values-minimal.yaml` | Minimal setup for testing and development | Development/testing |

### Custom Configuration

Create your own values file based on the examples:

```bash
cp values-production.yaml values-custom.yaml
# Edit values-custom.yaml as needed
./deploy.sh values-custom.yaml
```

## 🔧 Configuration

### Key Configuration Sections

#### Operators
```yaml
operators:
  enabled: true
  openshift-ai:
    enabled: true
    version: "stable-2.19"
    createInstances: true
  gpu-operator:
    enabled: true    # For GPU workloads
  # ... other operators
```

#### Applications
```yaml
applications:
  applications:
    enabled: true
    minio:
      enabled: true
      storageSize: "100Gi"
      credentials:
        username: "minio"
        password: "change-me-in-production"
```

#### Tenants
```yaml
tenants:
  tenants:
    enabled: true
    ai-example:
      enabled: true
      namespaces:
        - name: "ai-example"
          displayName: "AI Example Training"
      workbenches:
        enabled: true
      modelServing:
        enabled: true
      # ... other tenant configurations
```

## 🔍 Troubleshooting

### Common Issues

#### 1. MinIO Credentials Template Error
**Error**: `nil pointer evaluating interface {}.username`
**Solution**: Ensure proper credentials structure in values file:
```yaml
applications:
  applications:
    minio:
      credentials:
        username: "minio"
        password: "minio123"
```

#### 2. DataScienceCluster Not Ready
**Error**: `default-dsc False NotReady`
**Solution**: Check operator status and wait for components to initialize:
```bash
oc get datasciencecluster default-dsc -o yaml
oc get pods -n redhat-ods-operator
```

#### 3. CRD Not Found
**Warning**: `CRD datasciencepipelinesapplications.opendatahub.io not found`
**Solution**: This is usually a timing issue. The deployment will proceed and create workloads once CRDs are available.

#### 4. Operator Subscription Issues
**Error**: `constraints not satisfiable: no operators found in channel`
**Solution**: Verify operator channel names in values file match available channels in your OpenShift version.

### Debugging Commands

```bash
# Check Helm releases
helm list -n openshift-gitops

# Check operator status
oc get subscriptions -A
oc get csv -A

# Check OpenShift AI instances
oc get dscinitializations,datascienceclusters

# Check tenant namespaces
oc get namespaces | grep ai-example

# Check MinIO deployment
oc get all -n minio
```

## 🔄 Updating

### Upgrading Operators
```bash
# Update operator versions in values file, then redeploy
./deploy.sh values-production.yaml
```

### Adding New Tenants
```bash
# Edit values file to add new tenant configuration
# Then redeploy tenant workloads
./deploy.sh values-production.yaml
```

## 🧹 Cleanup

### Uninstall Everything
```bash
# Remove all Helm releases
helm uninstall ai-accelerator-tenants -n openshift-gitops
helm uninstall ai-accelerator-ai-instances -n openshift-gitops
helm uninstall ai-accelerator-operators -n openshift-gitops

# Clean up remaining resources
oc delete namespace minio
oc delete namespace ai-example ai-example-pipelines ai-example-single-model-serving ai-example-multi-model-serving ai-example-lmeval-lab
```

### Selective Cleanup
```bash
# Remove only tenant workloads
helm uninstall ai-accelerator-tenants -n openshift-gitops

# Remove only applications
# (Applications are included in tenants release)
```

## 📚 Documentation

### Deployment Phases

1. **Phase 1 - Operators**: Deploys all operator subscriptions and OperatorGroups
2. **Phase 2 - AI Instances**: Creates DataScienceCluster and DSCInitialization instances
3. **Phase 3 - Tenant Workloads**: Deploys applications and tenant-specific resources

### Idempotency

The deployment script is fully idempotent:
- Skips operator installation if already present
- Validates OpenShift AI instances before proceeding
- Waits for required CRDs before deploying dependent resources
- Handles existing resources gracefully

### Security Considerations

- Change default MinIO credentials in production
- Review operator versions and channels for security updates
- Configure appropriate RBAC for tenant namespaces
- Use secure storage classes for persistent volumes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `./deploy.sh values-minimal.yaml`
5. Submit a pull request

## 📝 Migration from Kustomize

This Helm chart provides identical functionality to the original Kustomize-based AI Accelerator project with these advantages:

- **Simplified Deployment**: Single script with different value files
- **Better Dependency Management**: Automatic handling of operator and CRD dependencies
- **Improved Maintainability**: Centralized configuration in values files
- **Enhanced Modularity**: Subchart architecture for better organization
- **Production Ready**: Robust error handling and idempotency

### Migration Steps

1. **Backup existing deployment**:
   ```bash
   oc get all -A > backup-resources.yaml
   ```

2. **Clean up Kustomize resources** (if needed):
   ```bash
   # Remove existing Kustomize-deployed resources
   ```

3. **Deploy with Helm**:
   ```bash
   ./deploy.sh values-production.yaml
   ```

## 🆘 Support

- **Issues**: Create GitHub issues for bugs or feature requests
- **Documentation**: Check existing documentation in `/documentation` folder
- **Examples**: Review different values files for configuration examples

## 🏷️ Tags

`#OpenShift` `#Kubernetes` `#Helm` `#AI` `#ML` `#DataScience` `#GitOps` `#Operators` `#RedHat`