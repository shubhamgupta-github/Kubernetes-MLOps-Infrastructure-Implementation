# Autoscaling Guide - Kubernetes HPA

Complete guide for implementing Horizontal Pod Autoscaling (HPA) for the ML Inference Service.

## Overview

This implementation provides CPU-based autoscaling for both tenant-a and tenant-b using Kubernetes HPA (Horizontal Pod Autoscaler).

**What it does:**
- Automatically scales pods from 2 to 10 replicas based on CPU usage
- Scales up when CPU > 50%
- Scales down when CPU < 50% (after 5 minutes)
- Works on local Kind cluster

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                         │
│                                                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Metrics Server                                      │    │
│  │  • Collects CPU/Memory metrics from nodes           │    │
│  │  • Exposes metrics API                              │    │
│  └─────────────────────────────────────────────────────┘    │
│                           ↓                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  HPA Controller                                      │    │
│  │  • Watches CPU metrics every 15s                    │    │
│  │  • Calculates desired replicas                      │    │
│  │  • Updates deployment                               │    │
│  └─────────────────────────────────────────────────────┘    │
│                           ↓                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  tenant-a Deployment                                 │    │
│  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐          │    │
│  │  │Pod 1│ │Pod 2│ │Pod 3│ │Pod 4│ │Pod 5│ ...      │    │
│  │  └─────┘ └─────┘ └─────┘ └─────┘ └─────┘          │    │
│  │  Min: 2 replicas  →  Max: 10 replicas              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  tenant-b Deployment                                 │    │
│  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                  │    │
│  │  │Pod 1│ │Pod 2│ │Pod 3│ │Pod 4│ ...               │    │
│  │  └─────┘ └─────┘ └─────┘ └─────┘                  │    │
│  │  Min: 2 replicas  →  Max: 10 replicas              │    │
│  └─────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘

Scaling Logic:
  CPU < 50% → Scale down (after 5 min stabilization)
  CPU > 50% → Scale up immediately
```

---

## Deployment Steps

### Step 1: Deploy Metrics Server (Required)

```bash
# Deploy metrics-server to Kind cluster
kubectl apply -f k8s-manifests/metrics-server/metrics-server.yaml

# Wait for it to be ready
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=300s

# Verify it's working
kubectl top nodes
kubectl top pods -n tenant-a
```

**Expected output:**
```
NAME                          CPU(cores)   MEMORY(bytes)
mlops-kind-cluster-control-plane   150m         500Mi
mlops-kind-cluster-worker          80m          300Mi
```

---

### Step 2: Deploy HPA Resources

```bash
# Deploy HPA for tenant-a
kubectl apply -f k8s-manifests/tenant-a/hpa.yaml

# Deploy HPA for tenant-b
kubectl apply -f k8s-manifests/tenant-b/hpa.yaml

# Verify HPAs are created
kubectl get hpa -n tenant-a
kubectl get hpa -n tenant-b
```

**Expected output:**
```
NAME                       REFERENCE                       TARGETS   MINPODS   MAXPODS   REPLICAS
tenant-a-ml-inference-hpa  Deployment/tenant-a-ml-inference   5%/50%   2         10        2
```

---

### Step 3: Monitor HPA Status

```bash
# Watch HPA in real-time (tenant-a)
kubectl get hpa -n tenant-a -w

# Watch pods scaling
kubectl get pods -n tenant-a -w

# View detailed HPA status
kubectl describe hpa tenant-a-ml-inference-hpa -n tenant-a
```

---

## Testing Autoscaling

### Option 1: Use Load Testing Script (Recommended)

**Windows:**
```powershell
.\test-autoscaling.ps1 -Tenant "tenant-a" -Duration 300 -Concurrency 10
```

**Linux/Mac:**
```bash
chmod +x test-autoscaling.sh
./test-autoscaling.sh tenant-a 300 10
```

**What it does:**
- Sends continuous requests to the ML service
- Generates CPU load to trigger autoscaling
- Runs for 5 minutes (300 seconds)
- 10 concurrent requests per second

### Option 2: Manual Load Generation

**Terminal 1** - Watch HPA:
```bash
kubectl get hpa -n tenant-a -w
```

**Terminal 2** - Watch Pods:
```bash
kubectl get pods -n tenant-a -w
```

**Terminal 3** - Generate Load:
```bash
# Port forward
kubectl port-forward -n tenant-a svc/tenant-a-ml-inference-svc 8000:8000

# In another terminal, generate load
while true; do
  curl -X POST http://localhost:8000/predict \
    -H "Content-Type: application/json" \
    -d '{"text": "Test autoscaling"}' &
done
```

---

## HPA Configuration Explained

### Basic Settings

```yaml
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: tenant-a-ml-inference  # Which deployment to scale
  
  minReplicas: 2    # Minimum pods (never goes below)
  maxReplicas: 10   # Maximum pods (never goes above)
  
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50  # Target 50% CPU
```

**How it works:**
- If average CPU across all pods > 50% → scale up
- If average CPU across all pods < 50% → scale down
- Desired replicas = current replicas × (current CPU / target CPU)

**Example:**
- Current: 2 pods at 80% CPU
- Desired: 2 × (80 / 50) = 3.2 → rounds to 4 pods

### Advanced Behavior Settings

```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 0      # Scale up immediately
    policies:
      - type: Percent
        value: 100                     # Can double pods
        periodSeconds: 15              # Every 15 seconds
      - type: Pods
        value: 2                       # Or add 2 pods
        periodSeconds: 15
    selectPolicy: Max                  # Use the bigger value
  
  scaleDown:
    stabilizationWindowSeconds: 300   # Wait 5 minutes before scaling down
    policies:
      - type: Percent
        value: 50                      # Remove 50% of pods
        periodSeconds: 15
```

**Scale Up Policy:**
- Happens immediately (no stabilization)
- Can add up to 100% more pods OR 2 pods (whichever is more)
- Checks every 15 seconds

**Scale Down Policy:**
- Waits 5 minutes of low CPU before starting
- Can remove up to 50% of pods at a time
- Gradual scale-down to avoid over-reaction

---

## Expected Behavior

### During Load Test

**Timeline:**

```
0:00 - Start: 2 pods, 10% CPU
      ↓ Load test starts
0:15 - CPU rises to 80%
0:30 - HPA detects high CPU
0:45 - Scales up to 4 pods
1:00 - CPU still high (60%)
1:15 - Scales up to 6 pods
1:30 - CPU stabilizes at 45%
      ↓ Stays at 6 pods
5:00 - Load test ends
5:15 - CPU drops to 20%
5:30 - Waits (stabilization period)
10:30 - Starts scaling down to 4 pods
11:00 - Scales down to 3 pods
11:30 - Scales down to 2 pods (minimum)
```

### Viewing Scaling Events

```bash
# View HPA events
kubectl describe hpa tenant-a-ml-inference-hpa -n tenant-a

# Look for messages like:
# - "New size: 4; reason: cpu resource utilization above target"
# - "New size: 2; reason: All metrics below target"
```

---

## Monitoring Commands

### Real-Time Monitoring

```bash
# Watch HPA status
watch kubectl get hpa -n tenant-a

# Watch pods
watch kubectl get pods -n tenant-a

# Watch CPU usage
watch kubectl top pods -n tenant-a

# View HPA metrics
kubectl get hpa tenant-a-ml-inference-hpa -n tenant-a -o yaml
```

### Check Scaling History

```bash
# View deployment events
kubectl describe deployment tenant-a-ml-inference -n tenant-a | grep -A 5 "Events"

# View HPA events
kubectl get events -n tenant-a --sort-by='.lastTimestamp' | grep HPA
```

---

## Tuning HPA

### Adjust CPU Target

If scaling too aggressively or not enough, adjust the target:

```yaml
# More sensitive (scales up at 30% CPU)
averageUtilization: 30

# Less sensitive (scales up at 70% CPU)
averageUtilization: 70
```

### Adjust Min/Max Replicas

```yaml
# Higher minimum for better availability
minReplicas: 3

# Higher maximum for more capacity
maxReplicas: 20
```

### Adjust Scale-Down Delay

```yaml
# Faster scale-down (1 minute)
stabilizationWindowSeconds: 60

# Slower scale-down (10 minutes)
stabilizationWindowSeconds: 600
```

---

## Troubleshooting

### Issue: HPA Shows "unknown" for CPU

```bash
kubectl get hpa -n tenant-a
# TARGETS: <unknown>/50%
```

**Cause**: Metrics server not ready or deployment missing resource requests

**Fix:**
```bash
# Check metrics-server
kubectl get pods -n kube-system | grep metrics-server

# Check if deployment has resource requests
kubectl get deployment tenant-a-ml-inference -n tenant-a -o yaml | grep -A 5 resources
```

**Deployment must have resource requests:**
```yaml
resources:
  requests:
    cpu: 100m    # Required for HPA!
```

### Issue: HPA Not Scaling

```bash
# Check HPA status
kubectl describe hpa tenant-a-ml-inference-hpa -n tenant-a

# Check current metrics
kubectl get hpa -n tenant-a

# Check if pods have CPU limits
kubectl top pods -n tenant-a
```

**Common causes:**
- CPU usage below target (nothing to scale)
- Metrics server not working
- Missing resource requests in deployment

### Issue: Pods Scale Up But Not Down

**Cause**: Stabilization window prevents rapid scale-down

**Solution**: This is normal! Wait for the stabilization period (5 minutes by default)

---

## Advanced: Memory-Based Autoscaling

You can also scale based on memory:

```yaml
metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
```

This scales based on EITHER CPU OR memory (whichever is higher).

---

## Performance Impact

### Resource Usage

**Per HPA:**
- CPU: < 1m
- Memory: < 10Mi

**Metrics Server:**
- CPU: ~100m
- Memory: ~200Mi

**Total overhead**: Minimal (~1% of cluster resources)

### Scaling Speed

- **Scale Up**: 15-45 seconds
- **Scale Down**: 5-10 minutes (due to stabilization)

---

## Best Practices

1. **Set Appropriate Resource Requests**
   ```yaml
   resources:
     requests:
       cpu: 100m      # Must be realistic
       memory: 128Mi
   ```

2. **Don't Set Min Too Low**
   - Minimum 2 for high availability
   - Avoid 1 replica (single point of failure)

3. **Set Reasonable Max**
   - Based on cluster capacity
   - Leave room for other workloads

4. **Monitor Scaling Patterns**
   - Adjust targets based on actual usage
   - Review HPA events regularly

5. **Test Scaling**
   - Run load tests before production
   - Verify scale-up and scale-down work

---

## Integration with CI/CD

HPA resources can be managed by your CI/CD pipeline:

```yaml
# In .github/workflows/ci-cd.yml
- name: Deploy HPA
  run: |
    kubectl apply -f k8s-manifests/tenant-a/hpa.yaml
    kubectl apply -f k8s-manifests/tenant-b/hpa.yaml
```

---

## Summary

✅ **Implemented**: CPU-based HPA for both tenants
✅ **Min replicas**: 2 (high availability)
✅ **Max replicas**: 10 (resource limits)
✅ **Target CPU**: 50% (balance performance/cost)
✅ **Scale up**: Immediate (responsive)
✅ **Scale down**: 5 min delay (stable)
✅ **Tested**: Load testing scripts provided

**Result**: Automatic, intelligent scaling based on actual load! 🚀

---

See `GPU_AUTOSCALING_GUIDE.md` for information about GPU autoscaling in cloud environments (EKS/GKE with Karpenter/Cluster Autoscaler).

