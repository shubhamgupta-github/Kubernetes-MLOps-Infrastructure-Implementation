# Kubernetes MLOps Infrastructure Implementation

Complete multi-tenant ML inference infrastructure deployed on Kubernetes with Terraform.

## 🎯 Project Overview

This project implements a production-ready MLOps infrastructure with:
- ✅ **Multi-tenant ML inference services** (FastAPI + scikit-learn)
- ✅ **Object storage** (MinIO)
- ✅ **RBAC-based tenant isolation**
- ✅ **NetworkPolicy-based network isolation**
- ✅ **Everything managed by Terraform**
- ✅ **Deployed on Kind (Kubernetes in Docker)**

## 📁 Project Structure

```
.
├── ml-inference-service/          # FastAPI + sklearn ML service
│   ├── app/
│   │   ├── main.py               # FastAPI application
│   │   └── requirements.txt      # Python dependencies
│   ├── Dockerfile                # Container definition
│   ├── build-and-load.ps1/sh    # Build scripts
│   └── test-api.ps1/sh           # API testing scripts
│
├── infra/
│   └── terraform/                # Terraform infrastructure
│       ├── main.tf               # Main deployment config
│       ├── providers.tf          # Kubernetes/Helm providers
│       ├── outputs.tf            # Terraform outputs
│       ├── namespaces.tf         # Tenant namespaces
│       ├── rbac.tf               # RBAC policies
│       ├── networkpolicies.tf    # Network policies
│       └── modules/
│           ├── cluster/          # Kind cluster module
│           ├── minio/            # MinIO deployment module
│           └── ml-inference/     # ML inference module
│
└── docs/
    ├── QUICK_START.md            # 5-step quick start guide
    ├── ARCHITECTURE.md           # Complete architecture diagrams
    ├── TASK_2_SUMMARY.md         # Implementation summary
    └── ML_INFERENCE_DEPLOYMENT_GUIDE.md  # Detailed deployment guide
```

## 🚀 Quick Manual Deploy (4 Steps)

### 1. Build & Load Docker Image
```bash
cd ml-inference-service
docker build -t ml-inference-service:latest .
kind load docker-image ml-inference-service:latest --name mlops-kind-cluster
cd ..
```

### 2. Deploy to Kubernetes
```bash
kubectl apply -f k8s-manifests/tenant-a/
kubectl apply -f k8s-manifests/tenant-b/
```

### 3. Verify Pods are Running
```bash
kubectl get pods -n tenant-a
kubectl get pods -n tenant-b
```

Wait for `Running` status (1-2 minutes).

### 4. Test the Services

**Tenant A:**
```bash
# Terminal 1
kubectl port-forward -n tenant-a svc/tenant-a-ml-inference-svc 8000:8000

# Terminal 2
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I love this product!"}'
```

**Tenant B:**
```bash
# Terminal 1  
kubectl port-forward -n tenant-b svc/tenant-b-ml-inference-svc 8001:8000

# Terminal 2
curl -X POST http://localhost:8001/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "This is terrible!"}'
```

---

## 📚 Helpful Guides

- **START_HERE.md** - Simplest guide, start here!
- **CHRONOLOGY.md** - Step-by-step timeline with explanations
- **SIMPLE_DEPLOYMENT_GUIDE.md** - Detailed manual deployment
- **k8s-manifests/README.md** - What each YAML file does

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (Kind)                       │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   minio      │  │   tenant-a   │  │   tenant-b   │      │
│  │  namespace   │  │  namespace   │  │  namespace   │      │
│  │              │  │              │  │              │      │
│  │  MinIO       │  │  ML Service  │  │  ML Service  │      │
│  │  Storage     │  │  + RBAC      │  │  + RBAC      │      │
│  │              │  │  + NetPolicy │  │  + NetPolicy │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                          ❌ ←────→ ❌                        │
│                    (Isolated by NetworkPolicy)               │
└─────────────────────────────────────────────────────────────┘
```

## 🔐 Security Features

### Multi-Layer Tenant Isolation

1. **Namespace Separation**
   - Each tenant in separate namespace
   - Logical resource boundary

2. **RBAC (Role-Based Access Control)**
   - ServiceAccount per tenant
   - Namespace-scoped Roles
   - Minimal permissions (least privilege)
   - No cross-tenant access

3. **NetworkPolicy**
   - Ingress: Only from same namespace
   - Egress: DNS + external APIs only
   - Blocks cross-tenant communication

4. **Resource Isolation**
   - CPU/Memory requests and limits
   - Prevents resource starvation
   - Fair resource allocation

## 📊 Deployed Resources

### MinIO (minio namespace)
- 1 Deployment (1 replica)
- 1 Service (NodePort)
- Object storage for ML models/data

### Tenant A (tenant-a namespace)
- 1 ServiceAccount (tenant-a-ml-inference-sa)
- 1 Role (minimal permissions)
- 1 RoleBinding
- 1 Deployment (2 replicas)
- 1 Service (ClusterIP)
- 1 NetworkPolicy (isolation)
- 1 ConfigMap

### Tenant B (tenant-b namespace)
- Same as Tenant A, isolated

**Total**: 3 namespaces, ~20 Kubernetes resources, 5 pods

## 🧪 Testing

### Functional Testing

Use the provided test scripts:

```powershell
# Windows
cd ml-inference-service
.\test-api.ps1 -Tenant "tenant-a" -Port 8000
```

```bash
# Linux/Mac
cd ml-inference-service
./test-api.sh tenant-a 8000
```

### RBAC Isolation Testing

```bash
# Should succeed (tenant-a accessing own namespace)
kubectl auth can-i list pods \
  --as=system:serviceaccount:tenant-a:tenant-a-ml-inference-sa -n tenant-a

# Should fail (tenant-a accessing tenant-b)
kubectl auth can-i list pods \
  --as=system:serviceaccount:tenant-a:tenant-a-ml-inference-sa -n tenant-b
```

### Network Isolation Testing

```bash
# Should timeout/fail (cross-tenant blocked)
kubectl exec -n tenant-a deployment/tenant-a-ml-inference -- \
  curl --max-time 5 tenant-b-ml-inference-svc.tenant-b:8000/health
```

## 🎯 API Endpoints

Each ML inference service exposes:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Service info and health |
| `/health` | GET | Liveness probe |
| `/ready` | GET | Readiness probe |
| `/predict` | POST | Sentiment prediction |
| `/metrics` | GET | Service metrics |

### Example Prediction Request

```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "text": "This product is amazing!"
  }'
```

### Example Response

```json
{
  "text": "This product is amazing!",
  "prediction": "positive",
  "confidence": 0.87,
  "tenant": "tenant-a"
}
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [QUICK_START.md](QUICK_START.md) | Fast 5-step deployment guide |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Complete architecture diagrams |
| [TASK_2_SUMMARY.md](TASK_2_SUMMARY.md) | Implementation details |
| [ML_INFERENCE_DEPLOYMENT_GUIDE.md](ML_INFERENCE_DEPLOYMENT_GUIDE.md) | Comprehensive deployment guide |
| [infra/terraform/MINIO_DEPLOYMENT_GUIDE.md](infra/terraform/MINIO_DEPLOYMENT_GUIDE.md) | MinIO deployment troubleshooting |

## 🛠️ Technology Stack

### Application Layer
- **FastAPI**: Modern Python web framework
- **scikit-learn**: Machine learning library
- **Uvicorn**: ASGI server
- **Pydantic**: Data validation

### Infrastructure Layer
- **Kubernetes**: Container orchestration (Kind)
- **Terraform**: Infrastructure as Code
- **Docker**: Container runtime
- **MinIO**: S3-compatible object storage

### Security Layer
- **RBAC**: Kubernetes role-based access control
- **NetworkPolicy**: Network segmentation
- **Pod Security**: Non-root containers, security contexts

## 🔧 Configuration

### Scaling Replicas

Edit `infra/terraform/main.tf`:

```hcl
module "ml_inference_tenant_a" {
  source = "./modules/ml-inference"
  replicas = 5  # Scale to 5 pods
}
```

### Adjusting Resources

```hcl
module "ml_inference_tenant_a" {
  source = "./modules/ml-inference"
  
  resource_requests_cpu    = "200m"
  resource_requests_memory = "256Mi"
  resource_limits_cpu      = "1000m"
  resource_limits_memory   = "1Gi"
}
```

### Adding New Tenants

```hcl
module "ml_inference_tenant_c" {
  source = "./modules/ml-inference"

  tenant_name           = "tenant-c"
  namespace             = kubernetes_namespace.tenant_c.metadata[0].name
  image                 = "ml-inference-service:latest"
  replicas              = 2
  enable_network_policy = true
  
  depends_on = [module.cluster, kubernetes_namespace.tenant_c]
}
```

## 🐛 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n tenant-a

# Describe pod for events
kubectl describe pod -n tenant-a <pod-name>

# Check logs
kubectl logs -n tenant-a <pod-name>
```

### Image Not Found

```bash
# Reload image into Kind
cd ml-inference-service
kind load docker-image ml-inference-service:latest --name mlops-kind-cluster

# Restart deployment
kubectl rollout restart deployment/tenant-a-ml-inference -n tenant-a
```

### Network Issues

```bash
# Check NetworkPolicies
kubectl get networkpolicy -n tenant-a
kubectl describe networkpolicy -n tenant-a tenant-a-ml-inference-netpol

# Temporarily disable for debugging
kubectl delete networkpolicy -n tenant-a tenant-a-ml-inference-netpol
```

## 📈 Monitoring

### Resource Usage

```bash
# Pod CPU/Memory usage
kubectl top pods -n tenant-a
kubectl top pods -n tenant-b

# Node usage
kubectl top nodes
```

### Logs

```bash
# Live logs
kubectl logs -f -n tenant-a deployment/tenant-a-ml-inference

# All replicas
kubectl logs -n tenant-a -l app=ml-inference,tenant=tenant-a
```

### Health Checks

```bash
# Check deployment health
kubectl get deployment -n tenant-a
kubectl get pods -n tenant-a

# Check service endpoints
kubectl get endpoints -n tenant-a
```

## 🚀 Production Enhancements

To make this production-ready, consider:

1. **Managed Kubernetes**: EKS, GKE, or AKS instead of Kind
2. **Ingress Controller**: NGINX or Traefik with TLS
3. **Certificate Management**: cert-manager for automated TLS
4. **Monitoring**: Prometheus + Grafana
5. **Logging**: ELK stack or Loki
6. **GitOps**: ArgoCD or Flux for deployments
7. **Container Registry**: ECR, GCR, or private registry
8. **Secrets Management**: HashiCorp Vault or AWS Secrets Manager
9. **Autoscaling**: HPA and Cluster Autoscaler
10. **Backup**: Velero for cluster backups

## 📋 Requirements

- Docker Desktop
- kubectl
- Terraform >= 1.5.0
- Kind (Kubernetes in Docker)
- Git Bash (Windows) or Bash (Linux/Mac)

## 🤝 Contributing

This is a demonstration project for MLOps infrastructure implementation.

## 📝 License

This project is for educational and demonstration purposes.

## 🎉 Success Criteria

You have successfully deployed if:

✅ All pods are running in all namespaces  
✅ ML inference services respond to predictions  
✅ RBAC isolation is enforced  
✅ NetworkPolicies block cross-tenant traffic  
✅ MinIO is accessible  
✅ All health checks pass  
✅ Resources are properly limited  

---

**Built with ❤️ for MLOps and DevOps Engineers**

For detailed guides, see the [QUICK_START.md](QUICK_START.md) and [ARCHITECTURE.md](ARCHITECTURE.md).
