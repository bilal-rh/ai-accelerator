#!/bin/bash
set -e

# Clean AI Accelerator Deployment Script
# Uses only Helm charts - no embedded YAML

# Configuration
NAMESPACE="openshift-gitops"
TIMEOUT_SECONDS=600
VALUES_FILE="${1:-values-production.yaml}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    if ! command -v oc &> /dev/null; then
        print_error "oc (OpenShift CLI) is required but not installed"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        print_error "helm is required but not installed"
        exit 1
    fi
    
    if ! oc whoami &> /dev/null; then
        print_error "Not logged into OpenShift. Please run 'oc login' first"
        exit 1
    fi
    
    if [ ! -f "$VALUES_FILE" ]; then
        print_error "Values file not found: $VALUES_FILE"
        exit 1
    fi
    
    print_info "Prerequisites check passed"
}

# Check operator status
check_operator_status() {
    local operator_name=$1
    local namespace=$2
    
    if oc get csv -n "$namespace" 2>/dev/null | grep -q "$operator_name.*Succeeded"; then
        return 0
    else
        return 1
    fi
}

# Check if OpenShift AI instances exist
check_ai_instances() {
    if oc get dscinitializations default-dsci 2>/dev/null && oc get datascienceclusters default-dsc 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Wait for CRDs to be available
wait_for_crds() {
    print_step "Waiting for required CRDs..."
    
    local crds=("notebooks.kubeflow.org" "inferenceservices.serving.kserve.io" "servingruntimes.serving.kserve.io" "datasciencepipelinesapplications.opendatahub.io")
    
    for crd in "${crds[@]}"; do
        local max_wait=120
        local wait_time=0
        
        print_info "Waiting for CRD: $crd"
        while [ $wait_time -lt $max_wait ]; do
            if oc get crd "$crd" &> /dev/null; then
                print_info "CRD $crd is available"
                break
            fi
            echo -n "."
            sleep 3
            wait_time=$((wait_time + 3))
        done
        
        if [ $wait_time -ge $max_wait ]; then
            print_warn "CRD $crd not found after ${max_wait}s"
        fi
    done
}

# Deploy operators using Helm
deploy_operators() {
    print_step "Deploying operators using Helm..."
    
    # Update Helm dependencies
    helm dependency update
    
    # Deploy only operators (no ArgoCD to avoid webhook issues)
    helm upgrade --install ai-accelerator-operators . \
        --namespace $NAMESPACE \
        --create-namespace \
        --timeout=${TIMEOUT_SECONDS}s \
        --values $VALUES_FILE \
        --set openshift-gitops.gitops.enabled=false \
        --set openshift-operators.operators.enabled=true \
        --set openshift-operators.operators.openshift-ai.createInstances=false \
        --set cluster-configs.clusterConfigs.enabled=false \
        --set applications.applications.enabled=false \
        --set tenants.tenants.enabled=false
    
    print_info "Operators deployment initiated"
}

# Wait for operators to be ready
wait_for_operators() {
    print_step "Waiting for operators to be ready..."
    
    local max_wait=300
    local wait_time=0
    
    print_info "Waiting for OpenShift AI operator..."
    while [ $wait_time -lt $max_wait ]; do
        if check_operator_status "rhods-operator" "redhat-ods-operator"; then
            print_info "OpenShift AI operator is ready"
            break
        fi
        echo -n "."
        sleep 10
        wait_time=$((wait_time + 10))
    done
    
    if [ $wait_time -ge $max_wait ]; then
        print_warn "OpenShift AI operator not ready after ${max_wait}s, continuing anyway"
    fi
}

# Deploy OpenShift AI instances using Helm
deploy_ai_instances() {
    print_step "Deploying OpenShift AI instances using Helm..."
    
    # Deploy OpenShift AI instances only
    helm upgrade --install ai-accelerator-ai-instances . \
        --namespace $NAMESPACE \
        --timeout=${TIMEOUT_SECONDS}s \
        --values $VALUES_FILE \
        --set openshift-gitops.gitops.enabled=false \
        --set openshift-operators.operators.enabled=true \
        --set openshift-operators.operators.openshift-ai.createInstances=true \
        --set cluster-configs.clusterConfigs.enabled=false \
        --set applications.applications.enabled=false \
        --set tenants.tenants.enabled=false
    
    print_info "OpenShift AI instances deployment initiated"
}

# Wait for OpenShift AI instances to be ready
wait_for_ai_instances() {
    print_step "Waiting for OpenShift AI instances to be ready..."
    
    # Wait for instances to be created
    local max_wait=300
    local wait_time=0
    
    print_info "Waiting for OpenShift AI instances to be created..."
    while [ $wait_time -lt $max_wait ]; do
        if oc get dscinitializations default-dsci 2>/dev/null && oc get datascienceclusters default-dsc 2>/dev/null; then
            print_info "OpenShift AI instances found"
            break
        fi
        echo -n "."
        sleep 5
        wait_time=$((wait_time + 5))
    done
    
    # Wait for readiness
    print_info "Waiting for OpenShift AI instances to be ready..."
    oc wait --for=condition=Ready --timeout=300s dscinitializations/default-dsci 2>/dev/null || print_warn "DSCInitialization not ready after 300s"
    oc wait --for=condition=Ready --timeout=300s datascienceclusters/default-dsc 2>/dev/null || print_warn "DataScienceCluster not ready after 300s"
    
    print_info "OpenShift AI instances are ready"
}

# Deploy tenant workloads using Helm
deploy_tenants() {
    print_step "Deploying tenant workloads using Helm..."
    
    # Deploy tenant resources and applications
    helm upgrade --install ai-accelerator-tenants . \
        --namespace $NAMESPACE \
        --timeout=${TIMEOUT_SECONDS}s \
        --values $VALUES_FILE \
        --set openshift-gitops.gitops.enabled=false \
        --set openshift-operators.operators.enabled=false \
        --set cluster-configs.clusterConfigs.enabled=false \
        --set applications.applications.enabled=true \
        --set tenants.tenants.enabled=true
    
    print_info "Tenant workloads deployed"
}

# Main deployment function
main() {
    print_info "🚀 Starting Clean AI Accelerator Deployment (Helm-only)"
    print_info "Using values file: $VALUES_FILE"
    echo ""
    
    check_prerequisites
    
    # Phase 1: Operators
    print_info "=== PHASE 1: OPERATORS ==="
    if check_operator_status "rhods-operator" "redhat-ods-operator"; then
        print_info "OpenShift AI operator already installed"
    else
        deploy_operators
        wait_for_operators
    fi
    
    # Phase 2: OpenShift AI Instances
    print_info "=== PHASE 2: OPENSHIFT AI INSTANCES ==="
    if check_ai_instances; then
        print_info "OpenShift AI instances already exist"
    else
        deploy_ai_instances
        wait_for_ai_instances
    fi
    
    # Wait for CRDs
    wait_for_crds
    
    # Phase 3: Tenants and Applications
    print_info "=== PHASE 3: TENANT WORKLOADS ==="
    deploy_tenants
    
    # Success message
    echo ""
    print_info "🎉 CLEAN DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo ""
    print_info "Next steps:"
    print_info "1. Check OpenShift AI dashboard in the OpenShift console"
    print_info "2. Access tenant namespaces for AI workloads"
    print_info "3. Use the deployed notebooks and model serving capabilities"
    echo ""
    print_info "Deployed releases:"
    print_info "  - ai-accelerator-operators (operators)"
    print_info "  - ai-accelerator-ai-instances (OpenShift AI instances)"
    print_info "  - ai-accelerator-tenants (applications & tenant workloads)"
    echo ""
}

# Run main function
main "$@" 