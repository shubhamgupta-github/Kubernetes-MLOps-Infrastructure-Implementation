# Kubernetes MLOps Infrastructure Implementation

Complete multi-tenant ML inference infrastructure deployed on Kubernetes.

## 🎯 Project Overview

This project implements a production-ready MLOps infrastructure with:
- ✅ **Multi-tenant ML inference services** (FastAPI + scikit-learn)
- ✅ **Object storage** (MinIO)
- ✅ **RBAC-based tenant isolation**
- ✅ **NetworkPolicy-based network isolation**
- ✅ **Horizontal Pod Autoscaling** (CPU-based)
- ✅ **CI/CD Pipeline** (GitHub Actions)
- ✅ **Monitoring & Alerting** (Prometheus + Grafana)
- ✅ **Security Scanning** (Trivy)
- ✅ **Deployed on Kind (Kubernetes in Docker)**

## 📁 Project Structure

```
.
├── ml-inference-service/          # FastAPI + sklearn ML service
│   ├── app/
│   │   ├── main.py               # FastAPI application
│   │   └── requirements.txt      # Python dependencies
│   ├── Dockerfile                # Container definition
│   ├── build-and-load.sh         # Build & load script
│   └── test-api.sh               # API testing script
│
├── infra/
│   └── terraform/                # Terraform infrastructure
│       ├── main.tf               # Main deployment config
│       ├── providers.tf          # Kubernetes/Helm providers
│       └── modules/
│           ├── cluster/          # Kind cluster module
│           └── minio/            # MinIO deployment module
│
├── k8s-manifests/                # Kubernetes YAML manifests
│   ├── tenant-a/                 # Tenant A resources
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── serviceaccount.yaml
│   │   ├── role.yaml
│   │   ├── rolebinding.yaml
│   │   ├── networkpolicy.yaml
│   │   └── hpa.yaml              # HPA for autoscaling
│   ├── tenant-b/                 # Tenant B resources (same)
│   └── metrics-server/           # Metrics Server for HPA
│
├── monitoring/                   # Prometheus + Grafana
│   ├── install-prometheus-grafana.ps1/sh
│   ├── servicemonitor.yaml       # Scrape config
│   ├── prometheusrule.yaml       # Alert rules
│   ├── dashboard.json            # Grafana dashboard
│   └── README.md
│
├── .github/workflows/
│   └── ci-cd.yml                 # GitHub Actions pipeline
│
├── test-autoscaling.ps1/sh       # Load testing for HPA
├── deploy.sh                     # Quick deployment script
└── docs/                         # Comprehensive guides
    ├── MONITORING_GUIDE.md
    ├── AUTOSCALING_GUIDE.md
    ├── GPU_AUTOSCALING_GUIDE.md
    ├── CI_CD_DOCUMENTATION.md
    └── EKS_DEPLOYMENT_GUIDE.md
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
| [k8s-manifests/README.md](k8s-manifests/README.md) | Kubernetes manifests explained |
| [MONITORING_GUIDE.md](MONITORING_GUIDE.md) | Prometheus + Grafana setup and usage |
| [AUTOSCALING_GUIDE.md](AUTOSCALING_GUIDE.md) | Kubernetes HPA implementation |
| [GPU_AUTOSCALING_GUIDE.md](GPU_AUTOSCALING_GUIDE.md) | GPU autoscaling documentation |
| [CI_CD_DOCUMENTATION.md](CI_CD_DOCUMENTATION.md) | GitHub Actions CI/CD pipeline |
| [EKS_DEPLOYMENT_GUIDE.md](EKS_DEPLOYMENT_GUIDE.md) | AWS EKS deployment guide |
| [CICD_SETUP.md](CICD_SETUP.md) | CI/CD setup quick reference |
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

## 📈 Monitoring & Alerting

This project includes **Prometheus + Grafana** for complete observability.

### Quick Setup (3 minutes)

```powershell
# Windows
cd monitoring
.\install-prometheus-grafana.ps1

# Deploy monitors & alerts
kubectl apply -f servicemonitor.yaml
kubectl apply -f prometheusrule.yaml
```

### Access Dashboards

- **Grafana**: http://localhost:30080 (admin/admin)
- **Prometheus**: http://localhost:30090

### What You Get

✅ **Dashboard**: Request rate, latency, pod status, CPU/memory  
✅ **Alerts**: High latency, pod restarts, errors, resource limits  
✅ **Real-time**: 10s refresh, 30s scrape interval  

See [MONITORING_GUIDE.md](MONITORING_GUIDE.md) for complete documentation.

---

## 🚀 Autoscaling

**Horizontal Pod Autoscaler (HPA)** automatically scales pods based on CPU usage.

### Deploy HPA

```bash
# Deploy Metrics Server
kubectl apply -f k8s-manifests/metrics-server/metrics-server.yaml

# Deploy HPA for both tenants
kubectl apply -f k8s-manifests/tenant-a/hpa.yaml
kubectl apply -f k8s-manifests/tenant-b/hpa.yaml
```

### Test Autoscaling

```powershell
# Generate load
.\test-autoscaling.ps1 -Tenant "tenant-a"

# Watch scaling in action
kubectl get hpa -n tenant-a -w
```

**Scaling config**:
- Min: 2 pods
- Max: 10 pods
- Target: 50% CPU
- Scale up: Immediate
- Scale down: After 5 minutes

See [AUTOSCALING_GUIDE.md](AUTOSCALING_GUIDE.md) and [GPU_AUTOSCALING_GUIDE.md](GPU_AUTOSCALING_GUIDE.md).

---

## 🔄 CI/CD Pipeline

**GitHub Actions** pipeline for automated build, scan, and push.

### What It Does

1. ✅ Builds Docker image
2. ✅ Scans for vulnerabilities (Trivy)
3. ✅ Pushes to Docker Hub
4. ✅ Documents EKS deployment

### Setup

1. Add GitHub Secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: Docker Hub access token (Read, Write, Delete)

2. Push to `main` branch → Pipeline triggers automatically

3. View workflow: **Actions** tab in GitHub

See [CI_CD_DOCUMENTATION.md](CI_CD_DOCUMENTATION.md) and [EKS_DEPLOYMENT_GUIDE.md](EKS_DEPLOYMENT_GUIDE.md).

---

## 🔍 Resource Monitoring

### CPU/Memory Usage

```bash
# Pod resource usage
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

## 🚀 Production Readiness

### ✅ Already Implemented

1. ✅ **Monitoring**: Prometheus + Grafana with dashboards and alerts
2. ✅ **Autoscaling**: Kubernetes HPA (CPU-based)
3. ✅ **CI/CD**: GitHub Actions with Trivy security scanning
4. ✅ **Multi-tenancy**: RBAC + NetworkPolicy isolation
5. ✅ **Health Checks**: Liveness and readiness probes
6. ✅ **Resource Limits**: CPU and memory constraints
7. ✅ **Security Scanning**: Trivy vulnerability scanning
8. ✅ **Documentation**: Complete guides for all components

### 🔄 For Production Migration

1. **Managed Kubernetes**: Migrate from Kind to EKS, GKE, or AKS
   - See [EKS_DEPLOYMENT_GUIDE.md](EKS_DEPLOYMENT_GUIDE.md)
2. **Ingress Controller**: NGINX or Traefik with TLS
3. **Certificate Management**: cert-manager for automated TLS
4. **Logging**: ELK stack or Loki for log aggregation
5. **GitOps**: ArgoCD or Flux for deployments
6. **Container Registry**: ECR, GCR, or private registry
7. **Secrets Management**: HashiCorp Vault or AWS Secrets Manager
8. **GPU Autoscaling**: Karpenter or Cluster Autoscaler
   - See [GPU_AUTOSCALING_GUIDE.md](GPU_AUTOSCALING_GUIDE.md)
9. **Backup**: Velero for cluster backups
10. **Service Mesh**: Istio or Linkerd for advanced traffic management

## 📋 Requirements

- **Docker Desktop**: Container runtime
- **kubectl**: Kubernetes CLI
- **Kind**: Kubernetes in Docker
- **Helm**: Kubernetes package manager (for monitoring)
- **Terraform >= 1.5.0**: Infrastructure as Code (optional)
- **Git**: Version control

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
✅ HPA is deployed and scaling works  
✅ Prometheus and Grafana are accessible  
✅ Grafana dashboard shows metrics  
✅ Alert rules are loaded in Prometheus  
✅ CI/CD pipeline builds and pushes images  
✅ Trivy security scanning completes  
✅ MinIO is accessible  
✅ All health checks pass  
✅ Resources are properly limited  

---

## 🌟 Complete Feature Set

This project demonstrates a **production-ready MLOps infrastructure** with:

| Feature | Implementation | Status |
|---------|----------------|--------|
| **Multi-tenant ML Inference** | FastAPI + scikit-learn | ✅ Complete |
| **Tenant Isolation** | RBAC + NetworkPolicy | ✅ Complete |
| **Object Storage** | MinIO (S3-compatible) | ✅ Complete |
| **Autoscaling** | Kubernetes HPA (CPU-based) | ✅ Complete |
| **Monitoring** | Prometheus + Grafana | ✅ Complete |
| **Alerting** | 6 alert rules configured | ✅ Complete |
| **CI/CD** | GitHub Actions pipeline | ✅ Complete |
| **Security Scanning** | Trivy vulnerability scanning | ✅ Complete |
| **Health Checks** | Liveness + Readiness probes | ✅ Complete |
| **Resource Management** | CPU/Memory limits | ✅ Complete |
| **Documentation** | Comprehensive guides | ✅ Complete |
| **Production Docs** | EKS/GPU deployment guides | ✅ Complete |

---

**Built with ❤️ for MLOps and DevOps Engineers**

Ready to deploy to production? See [EKS_DEPLOYMENT_GUIDE.md](EKS_DEPLOYMENT_GUIDE.md) for cloud deployment.
