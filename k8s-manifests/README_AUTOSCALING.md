# Autoscaling - Quick Reference

## What's Implemented

✅ **Kubernetes HPA (Horizontal Pod Autoscaler)**
- CPU-based autoscaling
- Works on local Kind cluster
- Scales tenant-a and tenant-b independently
- Min: 2 replicas, Max: 10 replicas
- Target: 50% CPU utilization

---

## Quick Deploy

### Step 1: Load Metrics Server Image (Required for Kind)

**Windows:**
```powershell
cd k8s-manifests/metrics-server
.\load-metrics-server.ps1
cd ..\..
```

**Linux/Mac:**
```bash
cd k8s-manifests/metrics-server
chmod +x load-metrics-server.sh
./load-metrics-server.sh
cd ../..
```

### Step 2: Deploy Metrics Server
```bash
kubectl apply -f k8s-manifests/metrics-server/metrics-server.yaml
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=300s
```

### Step 3: Deploy HPA
```bash
kubectl apply -f k8s-manifests/tenant-a/hpa.yaml
kubectl apply -f k8s-manifests/tenant-b/hpa.yaml
```

### Step 4: Verify
```bash
kubectl get hpa -n tenant-a
kubectl get hpa -n tenant-b
```

---

## Test Autoscaling

**Windows:**
```powershell
.\test-autoscaling.ps1 -Tenant "tenant-a"
```

**Linux/Mac:**
```bash
./test-autoscaling.sh tenant-a
```

**Watch it scale:**
```bash
# Terminal 1
kubectl get hpa -n tenant-a -w

# Terminal 2
kubectl get pods -n tenant-a -w
```

---

## Files

```
k8s-manifests/
├── metrics-server/
│   └── metrics-server.yaml         # Required for HPA
├── tenant-a/
│   └── hpa.yaml                     # HPA for tenant-a
└── tenant-b/
    └── hpa.yaml                     # HPA for tenant-b

test-autoscaling.sh                  # Load test script (Bash)
test-autoscaling.ps1                 # Load test script (PowerShell)
```

---

## Documentation

- **AUTOSCALING_GUIDE.md** - Complete HPA implementation guide
- **GPU_AUTOSCALING_GUIDE.md** - GPU autoscaling (theoretical, for cloud)

---

## Monitoring

```bash
# Check HPA status
kubectl get hpa -A

# Check CPU usage
kubectl top pods -n tenant-a

# Check node resources
kubectl top nodes

# View HPA details
kubectl describe hpa tenant-a-ml-inference-hpa -n tenant-a
```

---

## How It Works

```
CPU > 50% → Scale UP (immediately)
CPU < 50% → Scale DOWN (after 5 minutes)

Min replicas: 2
Max replicas: 10
```

**Example:**
- 2 pods at 80% CPU → Scales to 4 pods
- 4 pods at 30% CPU → Scales to 2 pods (after 5 min)

---

## Troubleshooting

**HPA shows "unknown":**
```bash
# Check metrics-server
kubectl get pods -n kube-system | grep metrics

# Restart if needed
kubectl rollout restart deployment metrics-server -n kube-system
```

**Pods not scaling:**
```bash
# Check CPU usage
kubectl top pods -n tenant-a

# Check HPA events
kubectl describe hpa tenant-a-ml-inference-hpa -n tenant-a
```

---

That's it! For detailed info, see `AUTOSCALING_GUIDE.md`.

