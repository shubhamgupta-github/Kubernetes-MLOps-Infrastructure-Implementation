# EKS Deployment Guide (Theoretical)

This guide documents how to deploy the ML Inference Service to Amazon EKS (Elastic Kubernetes Service) using the Docker images published to Docker Hub.

**Note**: This is documentation only. The current setup uses a local Kind cluster. This guide is for reference if you decide to deploy to AWS EKS in the future.

---

## Overview

```
┌──────────────────────────────────────────────────────────────┐
│                     Deployment Flow                           │
│                                                                │
│  GitHub Actions                                               │
│       │                                                        │
│       ├─► Build & Scan                                        │
│       │                                                        │
│       ├─► Push to Docker Hub                                  │
│       │   (vendettaopppp/ml-inference-service:SHA)           │
│       │                                                        │
│       └─► Deploy to EKS                                       │
│           │                                                    │
│           ├─► Configure kubectl for EKS                       │
│           │                                                    │
│           ├─► Update K8s manifests with new image tag         │
│           │                                                    │
│           └─► kubectl apply to EKS cluster                    │
│               │                                                │
│               ├─► Rolling update tenant-a deployment          │
│               │                                                │
│               └─► Rolling update tenant-b deployment          │
│                                                                │
│  Result: New version running in EKS                           │
└──────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### AWS Setup

1. **AWS Account** with EKS permissions
2. **EKS Cluster** already created
3. **IAM Role** for GitHub Actions with permissions:
   - `eks:DescribeCluster`
   - `eks:ListClusters`
   - Kubernetes RBAC permissions

4. **AWS Credentials** configured as GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`
   - `EKS_CLUSTER_NAME`

### Kubernetes Setup

1. **Namespaces** created: `tenant-a`, `tenant-b`
2. **RBAC** configured for deployments
3. **Service Account** for GitHub Actions deployments

---

## Option 1: Deployment with kubectl (Simple)

### GitHub Actions Workflow Addition

Add this job to `.github/workflows/ci-cd.yml`:

```yaml
deploy-to-eks:
  name: Deploy to EKS
  runs-on: ubuntu-latest
  needs: build-scan-push
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ secrets.AWS_REGION }}
        
    - name: Update kubeconfig for EKS
      run: |
        aws eks update-kubeconfig \
          --name ${{ secrets.EKS_CLUSTER_NAME }} \
          --region ${{ secrets.AWS_REGION }}
        
    - name: Verify cluster connection
      run: |
        kubectl cluster-info
        kubectl get nodes
        
    - name: Update image tag in manifests
      run: |
        # Update tenant-a deployment
        sed -i "s|image:.*ml-inference-service.*|image: vendettaopppp/ml-inference-service:sha-${{ needs.build-scan-push.outputs.sha_short }}|g" \
          k8s-manifests/tenant-a/deployment.yaml
        
        # Update tenant-b deployment
        sed -i "s|image:.*ml-inference-service.*|image: vendettaopppp/ml-inference-service:sha-${{ needs.build-scan-push.outputs.sha_short }}|g" \
          k8s-manifests/tenant-b/deployment.yaml
        
    - name: Deploy to tenant-a
      run: |
        kubectl apply -f k8s-manifests/tenant-a/
        kubectl rollout status deployment/tenant-a-ml-inference -n tenant-a --timeout=5m
        
    - name: Deploy to tenant-b
      run: |
        kubectl apply -f k8s-manifests/tenant-b/
        kubectl rollout status deployment/tenant-b-ml-inference -n tenant-b --timeout=5m
        
    - name: Verify deployments
      run: |
        echo "### Deployment Status" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "**Tenant A:**" >> $GITHUB_STEP_SUMMARY
        kubectl get pods -n tenant-a -o wide >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "**Tenant B:**" >> $GITHUB_STEP_SUMMARY
        kubectl get pods -n tenant-b -o wide >> $GITHUB_STEP_SUMMARY
```

### How It Works

1. **Authenticate to AWS** using secrets
2. **Configure kubectl** to point to EKS cluster
3. **Update manifests** with new image tag (SHA-based)
4. **Apply manifests** to Kubernetes
5. **Wait for rollout** to complete
6. **Verify** pods are running

### Rolling Update Process

Kubernetes performs a rolling update:
1. Creates new pod with new image
2. Waits for new pod to be ready (health checks pass)
3. Terminates old pod
4. Repeats for second replica
5. Result: Zero downtime deployment

---

## Option 2: Deployment with Helm (Recommended for Production)

### Why Helm?

- ✅ Templated configurations
- ✅ Version management
- ✅ Rollback capability
- ✅ Values per environment
- ✅ Better for multi-environment (dev/staging/prod)

### Helm Chart Structure

```
helm-chart/
├── Chart.yaml
├── values.yaml
├── values-prod.yaml
├── templates/
│   ├── namespace.yaml
│   ├── serviceaccount.yaml
│   ├── role.yaml
│   ├── rolebinding.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── networkpolicy.yaml
```

### Chart.yaml

```yaml
apiVersion: v2
name: ml-inference-service
description: ML Inference Service for multi-tenant deployment
type: application
version: 1.0.0
appVersion: "1.0.0"
```

### values.yaml

```yaml
# Default values for ml-inference-service
image:
  repository: vendettaopppp/ml-inference-service
  tag: latest
  pullPolicy: IfNotPresent

replicaCount: 2

tenantName: tenant-a

service:
  type: ClusterIP
  port: 8000

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

networkPolicy:
  enabled: true

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
```

### templates/deployment.yaml (excerpt)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.tenantName }}-ml-inference
  namespace: {{ .Values.tenantName }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: ml-inference
      tenant: {{ .Values.tenantName }}
  template:
    metadata:
      labels:
        app: ml-inference
        tenant: {{ .Values.tenantName }}
    spec:
      containers:
        - name: ml-inference
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          # ... rest of container spec
```

### GitHub Actions with Helm

```yaml
deploy-to-eks-helm:
  name: Deploy to EKS with Helm
  runs-on: ubuntu-latest
  needs: build-scan-push
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ secrets.AWS_REGION }}
        
    - name: Update kubeconfig for EKS
      run: |
        aws eks update-kubeconfig \
          --name ${{ secrets.EKS_CLUSTER_NAME }} \
          --region ${{ secrets.AWS_REGION }}
        
    - name: Install Helm
      uses: azure/setup-helm@v3
      with:
        version: '3.12.0'
        
    - name: Deploy tenant-a with Helm
      run: |
        helm upgrade --install tenant-a-ml-inference ./helm-chart \
          --namespace tenant-a \
          --create-namespace \
          --set image.tag=sha-${{ needs.build-scan-push.outputs.sha_short }} \
          --set tenantName=tenant-a \
          --wait \
          --timeout 5m
          
    - name: Deploy tenant-b with Helm
      run: |
        helm upgrade --install tenant-b-ml-inference ./helm-chart \
          --namespace tenant-b \
          --create-namespace \
          --set image.tag=sha-${{ needs.build-scan-push.outputs.sha_short }} \
          --set tenantName=tenant-b \
          --wait \
          --timeout 5m
          
    - name: Verify Helm releases
      run: |
        helm list -n tenant-a
        helm list -n tenant-b
```

### Helm Benefits

**Rollback Capability**:
```bash
# View history
helm history tenant-a-ml-inference -n tenant-a

# Rollback to previous version
helm rollback tenant-a-ml-inference -n tenant-a
```

**Environment-Specific Values**:
```bash
# Production
helm upgrade --install tenant-a-ml-inference ./helm-chart \
  -f values-prod.yaml

# Staging
helm upgrade --install tenant-a-ml-inference ./helm-chart \
  -f values-staging.yaml
```

---

## Option 3: GitOps with ArgoCD (Advanced)

### Why ArgoCD?

- ✅ Declarative GitOps
- ✅ Auto-sync from Git
- ✅ Visual deployment status
- ✅ Automatic rollback on failure
- ✅ Multi-cluster management

### Setup

1. **Install ArgoCD on EKS**:
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

2. **Create ArgoCD Application**:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ml-inference-tenant-a
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/YOUR_REPO
    targetRevision: main
    path: k8s-manifests/tenant-a
  destination:
    server: https://kubernetes.default.svc
    namespace: tenant-a
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

3. **GitHub Actions Updates Manifests**:
```yaml
update-manifests:
  name: Update Manifests for GitOps
  runs-on: ubuntu-latest
  needs: build-scan-push
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Update image tags
      run: |
        sed -i "s|image:.*ml-inference-service.*|image: vendettaopppp/ml-inference-service:sha-${{ needs.build-scan-push.outputs.sha_short }}|g" \
          k8s-manifests/tenant-a/deployment.yaml
        sed -i "s|image:.*ml-inference-service.*|image: vendettaopppp/ml-inference-service:sha-${{ needs.build-scan-push.outputs.sha_short }}|g" \
          k8s-manifests/tenant-b/deployment.yaml
        
    - name: Commit and push changes
      run: |
        git config user.name "GitHub Actions"
        git config user.email "actions@github.com"
        git add k8s-manifests/
        git commit -m "Update image to sha-${{ needs.build-scan-push.outputs.sha_short }}"
        git push
```

4. **ArgoCD Auto-Syncs**: Detects Git changes and deploys automatically

---

## Security Considerations

### 1. Image Pull from Docker Hub

**Public Repository** (current setup):
- No authentication needed
- Images publicly accessible
- Good for: Development, open source

**Private Repository** (production):
```yaml
# Create Docker Hub secret in Kubernetes
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=vendettaopppp \
  --docker-password=YOUR_TOKEN \
  --namespace=tenant-a

# Reference in deployment
spec:
  imagePullSecrets:
    - name: dockerhub-secret
```

### 2. RBAC for GitHub Actions

Create a service account with limited permissions:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: github-actions-deployer
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: deployment-manager
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "update", "patch"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: github-actions-deployer-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: deployment-manager
subjects:
  - kind: ServiceAccount
    name: github-actions-deployer
    namespace: kube-system
```

### 3. Network Policies in EKS

Ensure NetworkPolicies are enforced:
- Install Calico or AWS VPC CNI with network policy support
- Test policies before deploying

### 4. AWS IAM Roles

Use IRSA (IAM Roles for Service Accounts) instead of access keys:
```yaml
# In deployment
spec:
  serviceAccountName: ml-inference-sa
  
# Associate IAM role with service account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ml-inference-sa
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/MLInferenceRole
```

---

## Monitoring & Observability

### 1. CloudWatch Container Insights

Enable for EKS cluster:
```bash
aws eks update-cluster-config \
  --name YOUR_CLUSTER \
  --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'
```

### 2. Prometheus + Grafana

Deploy monitoring stack:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

### 3. Application Metrics

Expose from ML inference service:
```python
# Already has /metrics endpoint
# Prometheus will scrape automatically
```

---

## Cost Optimization

### 1. Use Spot Instances

```yaml
# EKS Node Group with spot instances
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: mlops-cluster
nodeGroups:
  - name: ml-inference-spot
    instancesDistribution:
      instanceTypes: ["t3.medium", "t3a.medium"]
      onDemandBaseCapacity: 0
      onDemandPercentageAboveBaseCapacity: 0
      spotAllocationStrategy: capacity-optimized
```

### 2. Horizontal Pod Autoscaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: tenant-a-ml-inference-hpa
  namespace: tenant-a
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: tenant-a-ml-inference
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### 3. Cluster Autoscaler

Automatically scale EKS nodes based on pod demands.

---

## Disaster Recovery

### 1. Multi-Region Deployment

Deploy to multiple AWS regions:
- Primary: `us-east-1`
- DR: `us-west-2`
- Use Route53 for failover

### 2. Backup with Velero

```bash
# Install Velero
velero install \
  --provider aws \
  --bucket mlops-backups \
  --backup-location-config region=us-east-1

# Schedule backups
velero schedule create daily-backup --schedule="0 2 * * *"
```

### 3. Database Backups

If using persistent storage, backup regularly:
```bash
# Automated EBS snapshots
aws dlm create-lifecycle-policy ...
```

---

## Comparison: Kind vs EKS

| Feature | Kind (Local) | EKS (Production) |
|---------|--------------|------------------|
| Cost | Free | ~$73/month + nodes |
| Scalability | Limited | Auto-scaling |
| High Availability | No | Multi-AZ |
| Load Balancer | NodePort only | ELB/ALB/NLB |
| Monitoring | Manual | CloudWatch |
| Managed Control Plane | No | Yes |
| Production Ready | No | Yes |
| Setup Time | 5 minutes | 15-30 minutes |

---

## Migration Path: Kind → EKS

### Step 1: Create EKS Cluster

```bash
eksctl create cluster \
  --name mlops-cluster \
  --region us-east-1 \
  --nodes 3 \
  --node-type t3.medium \
  --with-oidc \
  --managed
```

### Step 2: Update Image Pull Policy

Change in manifests:
```yaml
# From
imagePullPolicy: IfNotPresent

# To (for auto-updates)
imagePullPolicy: Always
```

### Step 3: Deploy with kubectl

```bash
kubectl apply -f k8s-manifests/tenant-a/
kubectl apply -f k8s-manifests/tenant-b/
```

### Step 4: Configure Ingress

```bash
# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system
```

### Step 5: Update CI/CD

Add EKS deployment step to GitHub Actions (as shown above).

---

## Summary

This guide provides three deployment approaches for EKS:

1. **kubectl** - Simple, direct deployment
2. **Helm** - Better for production, versioning
3. **ArgoCD** - GitOps, fully automated

**Current State**: Using Kind locally
**Future State**: Can deploy to EKS using this guide
**Recommendation**: Start with kubectl, migrate to Helm for production

All manifests in `k8s-manifests/` are compatible with both Kind and EKS! 🚀

