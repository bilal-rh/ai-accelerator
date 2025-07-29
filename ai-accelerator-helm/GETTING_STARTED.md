# Getting Started with AI Accelerator (Helm Edition)

This guide will help you deploy the AI Accelerator on your OpenShift cluster in under 10 minutes.

## ⚡ Prerequisites (2 minutes)

1. **OpenShift Cluster Access**
   ```bash
   # Verify you can access your cluster
   oc cluster-info
   oc whoami
   ```

2. **Required Tools**
   ```bash
   # Check Helm installation
   helm version
   # Should show v3.x.x
   
   # Check OpenShift CLI
   oc version
   # Should show both client and server versions
   ```

3. **Cluster Requirements**
   - OpenShift 4.12+ 
   - Cluster admin privileges
   - 50GB+ available storage
   - Internet connectivity for operator downloads

## 🚀 Quick Deploy (5 minutes)

### Option 1: Default Deployment
```bash
# Clone and deploy with defaults
cd ai-accelerator-helm
./bootstrap.sh

# Wait for completion (3-5 minutes)
```

### Option 2: Minimal Deployment (for testing)
```bash
# Deploy minimal version for testing
./bootstrap.sh -f values-minimal.yaml
```

### Option 3: GPU-Enabled Deployment
```bash
# Deploy with GPU support
./bootstrap.sh -f values-gpu.yaml
```

## 🎯 What Gets Deployed

### Core Platform
- ✅ OpenShift GitOps (ArgoCD)
- ✅ OpenShift AI Platform 
- ✅ MinIO S3 Storage

### Operators (Configurable)
- ✅ OpenShift AI Operator
- ✅ Authorino Operator  
- ✅ OpenShift Pipelines
- ✅ OpenShift Serverless
- ✅ OpenShift ServiceMesh

### AI/ML Workspaces
- ✅ Jupyter Workbenches
- ✅ Model Serving (TGIS, vLLM)
- ✅ Data Science Pipelines
- ✅ Example ML Projects

## 🔍 Verify Installation (2 minutes)

### Check Deployment Status
```bash
# Check Helm release
helm status ai-accelerator -n openshift-gitops

# Check operators
oc get csv -A | grep -E "(gitops|rhods|authorino)"

# Check pods
oc get pods -n openshift-gitops
oc get pods -n redhat-ods-operator
```

### Access the Platforms

1. **ArgoCD Dashboard**
   ```bash
   # Get ArgoCD URL
   oc get route openshift-gitops-server -n openshift-gitops
   ```

2. **OpenShift AI Dashboard**
   - Available through OpenShift Console → Application Launcher → Red Hat OpenShift AI

3. **MinIO Console** (if enabled)
   ```bash
   # Get MinIO URL
   oc get route minio-console -n minio
   # Default credentials: minio / minio123
   ```

## 🎛️ First Steps in OpenShift AI

1. **Create a Data Science Project**
   - Go to OpenShift AI Dashboard
   - Click "Data Science Projects" 
   - Click "Create data science project"
   - Name: "my-first-project"

2. **Launch a Workbench**
   - In your project, click "Create workbench"
   - Choose "Standard Data Science" image
   - Set storage to 10GB
   - Click "Create workbench"

3. **Start Experimenting**
   - Open Jupyter when workbench starts
   - Create a new notebook
   - Start your ML journey!

## 🛠️ Customization

### Modify Configuration
```bash
# Edit values file
cp values.yaml my-values.yaml
# Edit my-values.yaml with your preferences

# Upgrade deployment
./bootstrap.sh -f my-values.yaml
```

### Common Customizations

1. **Enable GPU Support**
   ```yaml
   operators:
     gpu-operator:
       enabled: true
   ```

2. **Increase Storage**
   ```yaml
   applications:
     minio:
       storageSize: "100Gi"
   ```

3. **Add Custom Workbench**
   ```yaml
   tenants:
     ai-example:
       workbenches:
         workbench:
           image: "my-custom-image:latest"
           storage: "50Gi"
   ```

## 🔧 Common Issues & Solutions

### 1. Operator Installation Stuck
```bash
# Check operator status
oc get subscription -A
oc get installplan -A

# Force refresh
oc delete pods -n openshift-operator-lifecycle-manager --all
```

### 2. Storage Issues
```bash
# Check available storage classes
oc get storageclass

# Update values file with correct storage class
storageClass: "your-storage-class"
```

### 3. ArgoCD Not Accessible
```bash
# Check route
oc get route -n openshift-gitops

# Restart ArgoCD if needed
oc delete pods -n openshift-gitops -l app.kubernetes.io/name=openshift-gitops-server
```

## 📚 Next Steps

1. **Explore Examples**
   - Check out the AI example workspace
   - Try the sample notebooks
   - Deploy a model using model serving

2. **Learn More**
   - Read the [full documentation](README.md)
   - Explore [OpenShift AI docs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed)
   - Check out [comparison with Kustomize](COMPARISON.md)

3. **Get Support**
   - Join the community discussions
   - Check troubleshooting guides
   - Review logs and configurations

## ⚠️ Important Notes

- **Default MinIO credentials** are not secure for production
- **Review security settings** before production use  
- **Monitor resource usage** during initial deployment
- **Backup configurations** before making changes

## 🎉 You're Ready!

Congratulations! You now have a complete AI/ML platform running on OpenShift. 

Start building amazing AI applications! 🚀 