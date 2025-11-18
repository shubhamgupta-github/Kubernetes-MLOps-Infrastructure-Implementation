# Kubernetes Manifests for ML Inference Service

Simple YAML files to deploy the ML inference service with `kubectl`.

## Structure

```
k8s-manifests/
├── tenant-a/          # All resources for tenant-a
│   ├── namespace.yaml
│   ├── serviceaccount.yaml
│   ├── role.yaml
│   ├── rolebinding.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── networkpolicy.yaml
│
└── tenant-b/          # All resources for tenant-b
    ├── namespace.yaml
    ├── serviceaccount.yaml
    ├── role.yaml
    ├── rolebinding.yaml
    ├── deployment.yaml
    ├── service.yaml
    └── networkpolicy.yaml
```

## Quick Deploy

### Deploy Tenant A
```bash
kubectl apply -f tenant-a/
```

### Deploy Tenant B
```bash
kubectl apply -f tenant-b/
```

### Deploy Both
```bash
kubectl apply -f tenant-a/
kubectl apply -f tenant-b/
```

## Resources Created

### Per Tenant:
- **Namespace**: Logical separation
- **ServiceAccount**: Identity for RBAC
- **Role**: Minimal permissions (get/list configmaps, secrets, pods)
- **RoleBinding**: Links ServiceAccount to Role
- **Deployment**: 2 replicas of ML inference app
- **Service**: ClusterIP to access the app
- **NetworkPolicy**: Network isolation

## What Each File Does

### namespace.yaml
Creates the namespace with labels for NetworkPolicy matching.

### serviceaccount.yaml
Creates a ServiceAccount that the pods will use (for RBAC).

### role.yaml
Defines what the ServiceAccount can do:
- Read ConfigMaps
- Read Secrets
- Read Pods (for self-discovery)

### rolebinding.yaml
Connects the ServiceAccount to the Role.

### deployment.yaml
The main application deployment:
- 2 replicas for high availability
- FastAPI + sklearn ML service
- Health checks (liveness & readiness)
- Resource limits (CPU/Memory)
- Security context (non-root user)
- Environment variable: TENANT_NAME

### service.yaml
ClusterIP service to access the deployment:
- Port 8000
- Targets all pods with matching labels

### networkpolicy.yaml
Network isolation:
- ✅ Allow ingress from same namespace only
- ✅ Allow egress to DNS (kube-system)
- ✅ Allow egress to external APIs
- ❌ Block cross-tenant traffic

## Verify Deployment

```bash
# Check all resources
kubectl get all -n tenant-a
kubectl get all -n tenant-b

# Check RBAC
kubectl get sa,role,rolebinding -n tenant-a

# Check NetworkPolicies
kubectl get networkpolicy -n tenant-a
kubectl get networkpolicy -n tenant-b
```

## Test the Service

### Tenant A:
```bash
kubectl port-forward -n tenant-a svc/tenant-a-ml-inference-svc 8000:8000

# In another terminal
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I love this!"}'
```

### Tenant B:
```bash
kubectl port-forward -n tenant-b svc/tenant-b-ml-inference-svc 8001:8000

# In another terminal
curl -X POST http://localhost:8001/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "This is terrible!"}'
```

## Update a Resource

Edit the YAML file and reapply:
```bash
# Edit the file
nano k8s-manifests/tenant-a/deployment.yaml

# Apply changes
kubectl apply -f k8s-manifests/tenant-a/deployment.yaml
```

## Delete Resources

### Delete specific tenant:
```bash
kubectl delete -f tenant-a/
kubectl delete -f tenant-b/
```

### Delete everything:
```bash
kubectl delete -f tenant-a/ -f tenant-b/
```

## Common Changes

### Scale replicas:
Edit `deployment.yaml`:
```yaml
spec:
  replicas: 5  # Change from 2 to 5
```

Apply:
```bash
kubectl apply -f tenant-a/deployment.yaml
```

### Change resource limits:
Edit `deployment.yaml`:
```yaml
resources:
  limits:
    cpu: "1000m"      # Change from 500m
    memory: "1Gi"     # Change from 512Mi
```

Apply:
```bash
kubectl apply -f tenant-a/deployment.yaml
```

## Security Features

### RBAC Isolation
- Each tenant has its own ServiceAccount
- Roles are namespace-scoped
- Minimal permissions (least privilege)
- No cluster-wide access

### Network Isolation
- NetworkPolicy blocks cross-tenant traffic
- Only same-namespace pods can communicate
- DNS access allowed
- External APIs allowed

### Container Security
- Runs as non-root user (UID 1000)
- No privilege escalation
- Resource limits enforced
- Security contexts applied

## Troubleshooting

### Pods not starting?
```bash
kubectl describe pod -n tenant-a <pod-name>
kubectl logs -n tenant-a <pod-name>
```

### Image not found?
```bash
# Load image into Kind
kind load docker-image ml-inference-service:latest --name mlops-kind-cluster

# Restart deployment
kubectl rollout restart deployment/tenant-a-ml-inference -n tenant-a
```

### NetworkPolicy blocking traffic?
```bash
# Temporarily delete to test
kubectl delete networkpolicy -n tenant-a tenant-a-ml-inference-netpol

# Test
# Re-apply when done
kubectl apply -f tenant-a/networkpolicy.yaml
```

## Notes

- All manifests use `IfNotPresent` for imagePullPolicy (good for Kind clusters)
- Service type is `ClusterIP` (internal only)
- NetworkPolicies require a CNI that supports them (Kind uses kindnet which does)
- Namespaces have labels for NetworkPolicy selector matching

