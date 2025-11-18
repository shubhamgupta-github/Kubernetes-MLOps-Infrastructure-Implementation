# GPU Autoscaling Guide (Theoretical)

Documentation for GPU autoscaling using Karpenter and Cluster Autoscaler in cloud environments (EKS/GKE/AKS).

**Note**: This is theoretical documentation. GPU autoscaling requires cloud infrastructure with GPU nodes. The current Kind cluster implementation uses CPU-based HPA (see `AUTOSCALING_GUIDE.md`).

---

## Overview

GPU autoscaling in Kubernetes involves two components:
1. **Horizontal Pod Autoscaler (HPA)** - Scales number of pods
2. **Cluster Autoscaler / Karpenter** - Scales number of GPU nodes

```
┌──────────────────────────────────────────────────────────────┐
│                     Cloud Provider (AWS/GCP/Azure)            │
│                                                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Kubernetes Cluster (EKS/GKE/AKS)                   │    │
│  │                                                       │    │
│  │  ┌─────────────────────────────────────────────┐   │    │
│  │  │  GPU Node Pool                               │   │    │
│  │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐     │   │    │
│  │  │  │ GPU Node│  │ GPU Node│  │ GPU Node│     │   │    │
│  │  │  │  (g4dn) │  │  (g4dn) │  │  (g4dn) │     │   │    │
│  │  │  └─────────┘  └─────────┘  └─────────┘     │   │    │
│  │  │       ↓             ↓             ↓          │   │    │
│  │  │    ML Pods      ML Pods      ML Pods        │   │    │
│  │  └─────────────────────────────────────────────┘   │    │
│  │                    ↑                                 │    │
│  │                    │                                 │    │
│  │  ┌─────────────────────────────────────────────┐   │    │
│  │  │  Karpenter / Cluster Autoscaler             │   │    │
│  │  │  • Monitors pending pods                    │   │    │
│  │  │  • Provisions GPU nodes on demand           │   │    │
│  │  │  • Removes idle GPU nodes                   │   │    │
│  │  └─────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

---

## Option 1: Karpenter (Recommended for AWS EKS)

Karpenter is a next-generation Kubernetes node autoscaler designed for cloud environments.

### Why Karpenter?

**Advantages:**
- ✅ Faster scaling (seconds vs minutes)
- ✅ Better bin-packing (more efficient)
- ✅ Automatic instance type selection
- ✅ Native support for Spot instances
- ✅ Simpler configuration

**vs Cluster Autoscaler:**
- Cluster Autoscaler: 1-2 minutes to provision nodes
- Karpenter: 30-60 seconds to provision nodes

### Architecture with Karpenter

```
Pod needs GPU → Karpenter detects → Provisions GPU node → Pod scheduled
              (5s)                (30-60s)           (10s)
Total: ~1 minute
```

### Prerequisites

**For AWS EKS:**
1. EKS cluster (1.21+)
2. IAM roles for Karpenter
3. VPC with subnets
4. GPU-enabled instance types available (g4dn, p3, etc.)

### Installation

```bash
# Add Karpenter Helm repo
helm repo add karpenter https://charts.karpenter.sh
helm repo update

# Create IAM role (simplified)
eksctl create iamserviceaccount \
  --cluster=mlops-cluster \
  --name=karpenter \
  --namespace=karpenter \
  --attach-policy-arn=arn:aws:iam::aws:policy/AmazonEKSClusterPolicy \
  --approve

# Install Karpenter
helm install karpenter karpenter/karpenter \
  --namespace karpenter \
  --create-namespace \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::ACCOUNT:role/KarpenterRole" \
  --set clusterName=mlops-cluster \
  --set clusterEndpoint=$(aws eks describe-cluster --name mlops-cluster --query "cluster.endpoint" --output text)
```

### Karpenter Provisioner for GPU Nodes

```yaml
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: gpu-provisioner
spec:
  # Requirements for GPU nodes
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["on-demand", "spot"]  # Allow spot for cost savings
    
    - key: node.kubernetes.io/instance-type
      operator: In
      values:
        - g4dn.xlarge      # 1 GPU, 4 vCPU, 16GB RAM
        - g4dn.2xlarge     # 1 GPU, 8 vCPU, 32GB RAM
        - g4dn.4xlarge     # 1 GPU, 16 vCPU, 64GB RAM
        - g4dn.8xlarge     # 1 GPU, 32 vCPU, 128GB RAM
    
    - key: kubernetes.io/arch
      operator: In
      values: ["amd64"]
    
    - key: karpenter.k8s.aws/instance-gpu-name
      operator: In
      values: ["t4"]  # NVIDIA T4 GPUs
  
  # Limits
  limits:
    resources:
      nvidia.com/gpu: "10"  # Max 10 GPUs across all nodes
  
  # Provider-specific configuration
  providerRef:
    name: gpu-node-template
  
  # Time to live settings
  ttlSecondsAfterEmpty: 300      # Remove node 5 min after last pod
  ttlSecondsUntilExpired: 604800 # Expire nodes after 7 days
  
  # Consolidation
  consolidation:
    enabled: true  # Bin-pack pods for efficiency
```

### Node Template for GPU Instances

```yaml
apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodeTemplate
metadata:
  name: gpu-node-template
spec:
  subnetSelector:
    karpenter.sh/discovery: mlops-cluster
  
  securityGroupSelector:
    karpenter.sh/discovery: mlops-cluster
  
  # Use optimized AMI for GPU workloads
  amiFamily: AL2  # Amazon Linux 2 with GPU drivers
  
  # User data to install NVIDIA drivers
  userData: |
    #!/bin/bash
    # Install NVIDIA drivers
    /etc/eks/bootstrap.sh mlops-cluster
    
    # Install NVIDIA container toolkit
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | \
      sudo tee /etc/yum.repos.d/nvidia-docker.repo
    yum install -y nvidia-container-toolkit
    systemctl restart docker
  
  # Block device mappings
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 100Gi
        volumeType: gp3
        encrypted: true
  
  # Tags
  tags:
    Environment: production
    ManagedBy: karpenter
    Team: mlops
```

### ML Inference Deployment with GPU

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gpu-ml-inference
  namespace: tenant-a
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ml-inference-gpu
  template:
    metadata:
      labels:
        app: ml-inference-gpu
    spec:
      # Node selector for GPU nodes
      nodeSelector:
        karpenter.sh/capacity-type: on-demand
        node.kubernetes.io/instance-type: g4dn.xlarge
      
      # Tolerations for Karpenter nodes
      tolerations:
        - key: nvidia.com/gpu
          operator: Exists
          effect: NoSchedule
      
      containers:
        - name: ml-inference
          image: vendettaopppp/ml-inference-gpu:latest
          resources:
            limits:
              nvidia.com/gpu: 1  # Request 1 GPU
              memory: 8Gi
              cpu: 4
            requests:
              nvidia.com/gpu: 1
              memory: 4Gi
              cpu: 2
          
          env:
            - name: CUDA_VISIBLE_DEVICES
              value: "0"
```

### HPA for GPU Workloads

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: gpu-ml-inference-hpa
  namespace: tenant-a
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: gpu-ml-inference
  
  minReplicas: 2
  maxReplicas: 10
  
  metrics:
    # GPU utilization (requires DCGM exporter)
    - type: Pods
      pods:
        metric:
          name: DCGM_FI_DEV_GPU_UTIL
        target:
          type: AverageValue
          averageValue: "70"  # 70% GPU utilization
    
    # CPU as fallback
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

### Scaling Flow with Karpenter

**Scenario: New GPU pod requested**

```
1. User increases replicas or HPA scales up
   ↓
2. New pod enters "Pending" state (no GPU node available)
   ↓ (5 seconds)
3. Karpenter detects pending pod with GPU request
   ↓
4. Karpenter evaluates requirements:
   - Needs: 1x nvidia.com/gpu
   - Instance type: g4dn.xlarge (cheapest that fits)
   - Capacity type: Spot (if configured)
   ↓
5. Karpenter provisions new EC2 instance
   ↓ (30-60 seconds)
6. Node joins cluster with GPU
   ↓ (10 seconds)
7. Pod scheduled to new GPU node
   ↓
8. Container starts, GPU initialized
   ↓
9. Pod Running ✅
```

**Total time**: ~1 minute (vs 2-3 minutes with Cluster Autoscaler)

---

## Option 2: Cluster Autoscaler (Classic Approach)

Cluster Autoscaler is the traditional Kubernetes node autoscaling solution.

### Why Cluster Autoscaler?

**Advantages:**
- ✅ More mature (battle-tested)
- ✅ Works on all cloud providers
- ✅ Simple node group model
- ✅ Well-documented

**Disadvantages:**
- ❌ Slower (1-2 minutes)
- ❌ Less efficient bin-packing
- ❌ Requires pre-defined node groups
- ❌ No automatic instance type selection

### Installation on EKS

```bash
# Deploy Cluster Autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Edit deployment to add cluster name
kubectl -n kube-system edit deployment cluster-autoscaler

# Add under command:
#   - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/mlops-cluster
```

### Create GPU Node Group

```bash
# Using eksctl
eksctl create nodegroup \
  --cluster=mlops-cluster \
  --name=gpu-nodes \
  --node-type=g4dn.xlarge \
  --nodes=0 \
  --nodes-min=0 \
  --nodes-max=10 \
  --node-labels="workload=gpu" \
  --node-ami-family=AmazonLinux2 \
  --install-nvidia-plugin=true \
  --asg-access
```

### Deployment with Cluster Autoscaler

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gpu-ml-inference
spec:
  replicas: 2
  template:
    spec:
      nodeSelector:
        workload: gpu
      containers:
        - name: ml-inference
          image: vendettaopppp/ml-inference-gpu:latest
          resources:
            limits:
              nvidia.com/gpu: 1
```

### Scaling Flow with Cluster Autoscaler

```
1. Pod pending (no GPU node)
   ↓ (15 seconds - evaluation interval)
2. Cluster Autoscaler detects pending pod
   ↓
3. Checks node groups that can satisfy requirements
   ↓
4. Scales ASG for gpu-nodes node group
   ↓ (60-120 seconds - EC2 launch time)
5. Node joins cluster
   ↓ (30 seconds - kubelet registration)
6. Pod scheduled
   ↓
7. Running ✅
```

**Total time**: ~2-3 minutes

---

## Comparison: Karpenter vs Cluster Autoscaler

| Feature | Karpenter | Cluster Autoscaler |
|---------|-----------|-------------------|
| **Scaling Speed** | 30-60s | 60-180s |
| **Bin-packing** | Excellent | Good |
| **Instance Selection** | Automatic | Manual (node groups) |
| **Spot Support** | Native | Via node groups |
| **Configuration** | Simple | Complex |
| **Maturity** | Newer | Battle-tested |
| **Cloud Support** | AWS (best), Azure/GCP (beta) | All clouds |
| **Cost Optimization** | Excellent | Good |

**Recommendation**: Use **Karpenter** for AWS EKS, **Cluster Autoscaler** for GKE/AKS or multi-cloud.

---

## GPU Monitoring

### Install DCGM Exporter (NVIDIA)

```bash
# Install NVIDIA DCGM exporter for GPU metrics
helm repo add gpu-helm-charts https://nvidia.github.io/dcgm-exporter/helm-charts
helm install dcgm-exporter gpu-helm-charts/dcgm-exporter \
  --namespace gpu-operator \
  --create-namespace
```

### GPU Metrics Available

- `DCGM_FI_DEV_GPU_UTIL` - GPU utilization %
- `DCGM_FI_DEV_MEM_COPY_UTIL` - Memory utilization %
- `DCGM_FI_DEV_GPU_TEMP` - GPU temperature
- `DCGM_FI_DEV_POWER_USAGE` - Power consumption

### Prometheus Query Examples

```promql
# Average GPU utilization
avg(DCGM_FI_DEV_GPU_UTIL{namespace="tenant-a"})

# GPU memory usage
sum(DCGM_FI_DEV_FB_USED / DCGM_FI_DEV_FB_FREE) by (gpu, pod)

# Pods per GPU node
count(kube_pod_info{node=~".*g4dn.*"}) by (node)
```

---

## Cost Optimization Strategies

### 1. Use Spot Instances

```yaml
# In Karpenter Provisioner
requirements:
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["spot"]  # 70% cost savings!
```

**Savings**: 70% cheaper than on-demand
**Risk**: Can be terminated with 2-minute notice

### 2. Right-size GPU Instances

| Instance | GPUs | vCPUs | RAM | Price/hr | Use Case |
|----------|------|-------|-----|----------|----------|
| g4dn.xlarge | 1 | 4 | 16GB | $0.526 | Small models |
| g4dn.2xlarge | 1 | 8 | 32GB | $0.752 | Medium models |
| p3.2xlarge | 1 | 8 | 61GB | $3.06 | Large models (V100) |
| p4d.24xlarge | 8 | 96 | 1152GB | $32.77 | Training workloads |

**Recommendation**: Start with g4dn.xlarge (T4 GPU), upgrade if needed.

### 3. Scale to Zero

```yaml
# In Karpenter Provisioner
ttlSecondsAfterEmpty: 300  # Remove node after 5 min idle
```

**Savings**: No cost when not running workloads

### 4. GPU Sharing (if applicable)

```yaml
# Multiple pods per GPU (if model is small)
resources:
  limits:
    nvidia.com/gpu: 0.5  # Share GPU (requires MIG or time-slicing)
```

---

## Production Best Practices

### 1. Use Mixed Capacity Types

```yaml
# 20% on-demand (reliable), 80% spot (cheap)
requirements:
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["on-demand", "spot"]

# Prefer on-demand for critical workloads
priorityClassName: high-priority
```

### 2. Set Resource Limits

```yaml
# Always set GPU requests/limits
resources:
  requests:
    nvidia.com/gpu: 1
    memory: 4Gi
  limits:
    nvidia.com/gpu: 1
    memory: 8Gi
```

### 3. Use Taints and Tolerations

```yaml
# Taint GPU nodes
kubectl taint nodes -l workload=gpu gpu=true:NoSchedule

# Only GPU workloads tolerate
tolerations:
  - key: gpu
    operator: Equal
    value: "true"
    effect: NoSchedule
```

This prevents non-GPU workloads from wasting expensive GPU nodes.

### 4. Monitor GPU Utilization

Set up alerts for:
- Low GPU utilization (< 30% for > 10 min)
- High GPU memory usage (> 90%)
- Pending pods waiting for GPU nodes

---

## Migration Path: CPU → GPU

### Current State (CPU-based)
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
```

### Future State (GPU-based)
```yaml
resources:
  requests:
    nvidia.com/gpu: 1
    memory: 4Gi
```

**Steps to migrate:**
1. Update model to use GPU (PyTorch/TensorFlow with CUDA)
2. Build GPU-enabled Docker image
3. Deploy Karpenter/Cluster Autoscaler
4. Create GPU node pool
5. Update deployment with GPU resource requests
6. Deploy and test
7. Monitor GPU utilization
8. Optimize (right-size instances, tune batch sizes)

---

## Summary

**For AWS EKS (Recommended):**
- ✅ Use **Karpenter** for fast, efficient GPU autoscaling
- ✅ Start with g4dn.xlarge (T4 GPU) for inference
- ✅ Use Spot instances for 70% cost savings
- ✅ Scale to zero when idle
- ✅ Monitor with DCGM + Prometheus

**For GKE/AKS:**
- ✅ Use **Cluster Autoscaler**
- ✅ Similar configuration with cloud-specific node pools

**Current Implementation:**
- ✅ CPU-based HPA works on Kind cluster
- ✅ Ready to migrate to GPU when moving to cloud

**Cost Estimate (AWS):**
- g4dn.xlarge spot: ~$0.16/hour
- 2 replicas 24/7: ~$230/month
- Scale to zero nights/weekends: ~$80/month

See `AUTOSCALING_GUIDE.md` for the working CPU-based HPA implementation on Kind.

