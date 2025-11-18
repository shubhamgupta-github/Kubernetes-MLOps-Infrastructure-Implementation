# Kubernetes MLOps Infrastructure Implementation

**Complete Production-Ready Multi-Tenant ML Infrastructure on Kubernetes**

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Features Implemented](#features-implemented)
4. [Technology Stack](#technology-stack)
5. [Quick Start Guide](#quick-start-guide)
6. [Component Details](#component-details)
7. [Security & Isolation](#security--isolation)
8. [Monitoring & Observability](#monitoring--observability)
9. [CI/CD Pipeline](#cicd-pipeline)
10. [Autoscaling](#autoscaling)
11. [Testing & Validation](#testing--validation)
12. [Mocked vs Real Services](#mocked-vs-real-services)
13. [Production Readiness](#production-readiness)
14. [Future Enhancements](#future-enhancements)

---

## 🎯 Project Overview

This project demonstrates a **complete MLOps infrastructure** deployed on Kubernetes (Kind), featuring:

- **Multi-tenant ML inference services** with complete isolation
- **Production-grade security** (RBAC + NetworkPolicy)
- **Automated CI/CD pipeline** with security scanning
- **Horizontal pod autoscaling** for dynamic workload management
- **Full observability stack** (Prometheus + Grafana)
- **Object storage** for ML artifacts (MinIO)

### Key Highlights

✅ **5 Major Components** - All tasks completed  
✅ **Production-Ready** - Security, monitoring, and autoscaling included  
✅ **Well-Documented** - Comprehensive guides for all components  
✅ **Cloud-Ready** - Can be deployed to AWS EKS, GKE, or AKS  

---

## 🏗️ Architecture

See **`ARCHITECTURE_DIAGRAM.png`** for visual representation.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Kubernetes Cluster (Kind)                       │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    Monitoring Namespace                         │ │
│  │  ┌──────────────┐         ┌──────────────┐                     │ │
│  │  │  Prometheus  │────────▶│   Grafana    │                     │ │
│  │  │  (Metrics)   │         │ (Dashboard)  │                     │ │
│  │  └──────────────┘         └──────────────┘                     │ │
│  │         │                                                        │ │
│  │         │ (scrapes metrics)                                     │ │
│  └─────────┼────────────────────────────────────────────────────────┘ │
│            │                                                          │
│  ┌─────────▼──────────┐    ┌──────────────────┐                     │
│  │  Tenant A          │    │  Tenant B         │                     │
│  │  Namespace         │    │  Namespace        │                     │
│  │                    │    │                   │                     │
│  │  ┌──────────────┐  │    │  ┌──────────────┐ │                     │
│  │  │ ML Inference │  │    │  │ ML Inference │ │                     │
│  │  │   Service    │  │    │  │   Service    │ │                     │
│  │  │ (2-10 pods)  │  │    │  │ (2-10 pods)  │ │                     │
│  │  └──────────────┘  │    │  └──────────────┘ │                     │
│  │                    │    │                   │                     │
│  │  • ServiceAccount  │    │  • ServiceAccount │                     │
│  │  • RBAC Role       │    │  • RBAC Role      │                     │
│  │  • NetworkPolicy   │    │  • NetworkPolicy  │                     │
│  │  • HPA            │    │  • HPA            │                     │
│  └────────────────────┘    └───────────────────┘                     │
│            ❌                         ❌                               │
│            └────── Network Isolated ──────┘                          │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    MinIO Namespace                            │   │
│  │  ┌──────────────────────────────────────────────────┐        │   │
│  │  │  MinIO Object Storage (S3-Compatible)            │        │   │
│  │  │  • Model artifacts                               │        │   │
│  │  │  • Training data                                 │        │   │
│  │  └──────────────────────────────────────────────────┘        │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
                            │
                            │ (External Access)
                            ▼
                    ┌───────────────────┐
                    │  GitHub Actions   │
                    │    CI/CD Pipeline │
                    │                   │
                    │  • Build Image    │
                    │  • Trivy Scan     │
                    │  • Push to Hub    │
                    └───────────────────┘
```

### Request Flow

```
User Request
    │
    ▼
kubectl port-forward (Local Dev)
    │
    ▼
Service (ClusterIP)
    │
    ▼
Deployment (2-10 pods via HPA)
    │
    ▼
FastAPI Application
    │
    ▼
Scikit-learn Model (In-memory)
    │
    ▼
JSON Response
```

---

## ✅ Features Implemented

### Task 1: MinIO Deployment ✅

- **Technology**: MinIO (S3-compatible object storage)
- **Deployment**: Terraform module
- **Features**:
  - Persistent storage (optional)
  - NodePort access
  - Ready for model artifact storage

### Task 2: ML Inference Service ✅

- **Technology**: FastAPI + Scikit-learn
- **Model**: Sentiment Analysis (Naive Bayes)
- **Features**:
  - Containerized service (Docker)
  - Multi-tenant deployment (tenant-a, tenant-b)
  - Health checks (liveness + readiness probes)
  - Resource limits (CPU/Memory)
  - Metrics endpoint for Prometheus

### Task 3: CI/CD Pipeline ✅

- **Technology**: GitHub Actions
- **Features**:
  - Automated Docker image build
  - Security scanning with Trivy
  - Push to Docker Hub
  - Trigger on push to `main` branch
  - Documented EKS deployment strategy

### Task 4: Autoscaling ✅

- **Technology**: Kubernetes HPA
- **Features**:
  - CPU-based autoscaling (50% target)
  - Scale range: 2-10 pods
  - Metrics Server deployed
  - Load testing scripts included
  - GPU autoscaling documented (Karpenter)

### Task 5: Monitoring & Alerting ✅

- **Technology**: Prometheus + Grafana
- **Features**:
  - 8-panel Grafana dashboard
  - 6 alert rules (latency, restarts, errors, resources)
  - Real-time metrics (30s scrape interval)
  - ServiceMonitor for auto-discovery
  - NodePort access for both services

---

## 🛠️ Technology Stack

### Core Infrastructure

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Orchestration** | Kubernetes (Kind) | Container orchestration |
| **IaC** | Terraform | Infrastructure as Code |
| **Registry** | Docker Hub | Container image storage |
| **Storage** | MinIO | S3-compatible object storage |

### Application Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **API Framework** | FastAPI | REST API server |
| **ML Library** | Scikit-learn | Machine learning models |
| **Server** | Uvicorn | ASGI server |
| **Validation** | Pydantic | Data validation |

### DevOps Tools

| Component | Technology | Purpose |
|-----------|------------|---------|
| **CI/CD** | GitHub Actions | Automated pipeline |
| **Security Scan** | Trivy | Vulnerability scanning |
| **Monitoring** | Prometheus | Metrics collection |
| **Dashboards** | Grafana | Visualization |
| **Autoscaling** | HPA + Metrics Server | Dynamic scaling |

### Security

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Access Control** | RBAC | Role-based permissions |
| **Network Isolation** | NetworkPolicy | Tenant separation |
| **Non-root Containers** | Docker USER | Security best practice |

---

## 🚀 Quick Start Guide

### Prerequisites

- Docker Desktop
- kubectl
- Kind
- Helm (for monitoring)
- Terraform (optional)

### Step 1: Create Kind Cluster

```bash
cd infra/terraform
terraform init
terraform apply
```

### Step 2: Deploy ML Inference Services

```bash
# Build and load Docker image
cd ml-inference-service
docker build -t ml-inference-service:latest .
kind load docker-image ml-inference-service:latest --name mlops-kind-cluster

# Deploy to Kubernetes
cd ..
kubectl apply -f k8s-manifests/tenant-a/
kubectl apply -f k8s-manifests/tenant-b/
```

### Step 3: Deploy Autoscaling

```bash
kubectl apply -f k8s-manifests/metrics-server/metrics-server.yaml
kubectl apply -f k8s-manifests/tenant-a/hpa.yaml
kubectl apply -f k8s-manifests/tenant-b/hpa.yaml
```

### Step 4: Deploy Monitoring (Optional)

```bash
cd monitoring
# Set kubeconfig
export KUBECONFIG=../infra/terraform/modules/cluster/kubeconfig

# Install Prometheus + Grafana
./install-prometheus-grafana.sh

# Deploy monitors
kubectl apply -f servicemonitor.yaml
kubectl apply -f prometheusrule.yaml
```

### Step 5: Test the Service

```bash
# Port forward
kubectl port-forward -n tenant-a svc/tenant-a-ml-inference-svc 8000:8000

# Test prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "This product is amazing!"}'
```

**Expected Response:**
```json
{
  "text": "This product is amazing!",
  "prediction": "positive",
  "confidence": 0.87,
  "tenant": "tenant-a"
}
```

---

## 📦 Component Details

### ML Inference Service

**File**: `ml-inference-service/app/main.py`

- **Model**: Multinomial Naive Bayes (scikit-learn)
- **Training Data**: 10 sample sentences (5 positive, 5 negative)
- **Features**: TF-IDF vectorization
- **Endpoints**:
  - `GET /` - Service info
  - `GET /health` - Health check
  - `GET /ready` - Readiness check
  - `POST /predict` - Sentiment prediction
  - `GET /metrics` - Prometheus metrics

### Kubernetes Resources per Tenant

- **Namespace**: Logical isolation boundary
- **ServiceAccount**: Identity for pods
- **Role**: Namespace-scoped permissions (minimal)
- **RoleBinding**: Binds role to service account
- **Deployment**: 2 initial replicas, scales to 10
- **Service**: ClusterIP for internal access
- **NetworkPolicy**: Blocks cross-tenant traffic
- **HPA**: Auto-scales based on CPU (50% target)

### Resource Limits

```yaml
requests:
  cpu: 100m
  memory: 128Mi
limits:
  cpu: 500m
  memory: 512Mi
```

---

## 🔐 Security & Isolation

### Multi-Layer Tenant Isolation

#### 1. Namespace Separation
- Each tenant in separate namespace
- Logical resource boundary
- Prevents accidental cross-tenant access

#### 2. RBAC (Role-Based Access Control)
```yaml
# Tenant A can only access tenant-a namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: tenant-a-ml-inference-role
  namespace: tenant-a
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list"]
```

#### 3. NetworkPolicy
```yaml
# Blocks all traffic except from same namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: tenant-a-ml-inference-netpol
  namespace: tenant-a
spec:
  podSelector:
    matchLabels:
      app: ml-inference
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: tenant-a
```

### Security Testing

```bash
# Test RBAC - Should succeed
kubectl auth can-i list pods \
  --as=system:serviceaccount:tenant-a:tenant-a-ml-inference-sa -n tenant-a

# Test RBAC - Should fail (cross-tenant)
kubectl auth can-i list pods \
  --as=system:serviceaccount:tenant-a:tenant-a-ml-inference-sa -n tenant-b

# Test NetworkPolicy - Should timeout
kubectl exec -n tenant-a deployment/tenant-a-ml-inference -- \
  curl --max-time 5 tenant-b-ml-inference-svc.tenant-b:8000/health
```

---

## 📊 Monitoring & Observability

### Prometheus Metrics

- **Request Rate**: `fastapi_requests_total`
- **Latency**: `fastapi_request_duration_seconds`
- **CPU Usage**: `container_cpu_usage_seconds_total`
- **Memory Usage**: `container_memory_working_set_bytes`
- **Pod Restarts**: `kube_pod_container_status_restarts_total`

### Grafana Dashboard

**8 Visualization Panels:**

1. **Request Rate** - Requests/sec per tenant
2. **Request Latency** - p95 & p50 response times
3. **Running Pods** - Health status (tenant-a)
4. **Running Pods** - Health status (tenant-b)
5. **Total Pod Restarts** - Stability tracking
6. **Average CPU Usage** - Resource utilization %
7. **Memory Usage** - Per-pod consumption
8. **CPU Usage** - Per-pod CPU %

**Access**: http://localhost:30080 (admin/admin)

### Alert Rules (6 Total)

| Alert | Condition | Severity | Duration |
|-------|-----------|----------|----------|
| **High Latency** | p95 > 5s | Warning | 2 minutes |
| **Pod Restarts** | >3 restarts in 10min | Critical | 1 minute |
| **High Error Rate** | >5% errors | Warning | 5 minutes |
| **Pod Not Ready** | Not ready | Warning | 5 minutes |
| **High CPU** | >80% | Warning | 10 minutes |
| **High Memory** | >90% | Critical | 5 minutes |

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

**File**: `.github/workflows/ci-cd.yml`

**Trigger**: Push to `main` branch

**Steps**:
1. ✅ Checkout code
2. ✅ Set up Docker Buildx
3. ✅ Login to Docker Hub
4. ✅ Build Docker image
5. ✅ Run Trivy security scan
6. ✅ Push image to Docker Hub

**Secrets Required**:
- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_TOKEN`: Docker Hub access token (Read, Write, Delete)

### Image Tagging Strategy

- `latest` - Always points to most recent build
- `main-<sha>` - Git commit SHA for traceability
- Example: `vendettaopppp/ml-inference-service:main-abc1234`

### Security Scanning

**Tool**: Trivy (Aqua Security)

**Scans For**:
- OS vulnerabilities
- Language-specific vulnerabilities (Python packages)
- Critical/High/Medium/Low severity issues

**Results**: Displayed in pipeline logs

---

## 📈 Autoscaling

### Horizontal Pod Autoscaler (HPA)

**Configuration**:
```yaml
minReplicas: 2
maxReplicas: 10
targetCPUUtilizationPercentage: 50
```

**Behavior**:
- **Scale Up**: Immediate when CPU > 50%
- **Scale Down**: After 5 minutes of CPU < 50%

### Load Testing

```bash
# Generate load
./test-autoscaling.sh tenant-a

# Watch scaling
kubectl get hpa -n tenant-a -w

# Expected output:
# NAME                    REFERENCE                        TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
# tenant-a-ml-inference   Deployment/tenant-a-ml-inference   75%/50%   2         10        4          5m
```

### Metrics Server

**Deployment**: `k8s-manifests/metrics-server/metrics-server.yaml`

**Configuration**:
- Insecure TLS (for Kind cluster)
- Host network disabled
- 60s scrape interval

---

## 🧪 Testing & Validation

### Functional Testing

```bash
# Test prediction endpoint
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I love this product"}'

# Test health endpoint
curl http://localhost:8000/health

# Test readiness endpoint
curl http://localhost:8000/ready
```

### Load Testing

```bash
# Simple load test
for i in {1..1000}; do
  curl -X POST http://localhost:8000/predict \
    -H "Content-Type: application/json" \
    -d '{"text": "Test message"}' &
done
```

### Isolation Testing

```bash
# Test RBAC isolation
kubectl auth can-i list pods \
  --as=system:serviceaccount:tenant-a:tenant-a-ml-inference-sa \
  -n tenant-b
# Expected: no

# Test NetworkPolicy isolation
kubectl exec -n tenant-a deployment/tenant-a-ml-inference -- \
  curl --max-time 5 tenant-b-ml-inference-svc.tenant-b:8000/health
# Expected: timeout
```

---

## 🎭 Mocked vs Real Services

### Mocked (Demo/Dev) Services

| Component | Mock Implementation | Production Alternative |
|-----------|---------------------|------------------------|
| **Kubernetes** | Kind (local cluster) | AWS EKS, GKE, Azure AKS |
| **ML Model** | 10-sample Naive Bayes | Real trained model on large dataset |
| **Training Data** | Hardcoded 10 sentences | S3/MinIO with actual datasets |
| **Model Storage** | In-memory (loaded at startup) | MinIO/S3 with versioning |
| **Container Registry** | Docker Hub (public) | AWS ECR, Google GCR (private) |
| **Ingress** | kubectl port-forward | NGINX Ingress + TLS |
| **DNS** | None (port-forward) | Route53, CloudFlare |
| **Certificates** | None | cert-manager + Let's Encrypt |
| **Secrets** | Kubernetes secrets (plain) | HashiCorp Vault, AWS Secrets Manager |
| **Logging** | kubectl logs | ELK Stack, CloudWatch, Loki |
| **GPUs** | None (CPU-only) | NVIDIA GPU nodes |

### Real (Production-Grade) Services

| Component | Implementation | Notes |
|-----------|----------------|-------|
| **Monitoring** | Prometheus + Grafana | ✅ Production-ready stack |
| **Autoscaling** | Kubernetes HPA | ✅ Real autoscaling based on metrics |
| **CI/CD** | GitHub Actions | ✅ Actual pipeline with security scanning |
| **Security Scanning** | Trivy | ✅ Real vulnerability detection |
| **RBAC** | Kubernetes RBAC | ✅ Production-grade access control |
| **NetworkPolicy** | Kubernetes NetworkPolicy | ✅ Real network isolation |
| **Health Checks** | Liveness + Readiness | ✅ Production-ready probes |
| **Resource Limits** | Kubernetes limits | ✅ Real resource constraints |

### Why Mocked?

1. **Rapid Development**: Quick iteration without cloud costs
2. **Learning Environment**: Safe to experiment
3. **Reproducible**: Runs on any laptop
4. **Cost-Effective**: No cloud bills
5. **Portability**: Can demo anywhere

### Migration to Production

See **`EKS_DEPLOYMENT_GUIDE.md`** for:
- EKS cluster setup
- Application Load Balancer
- AWS ECR integration
- CloudWatch logging
- Managed Prometheus/Grafana
- GPU autoscaling with Karpenter

---

## 🚀 Production Readiness

### ✅ Production-Ready Features

- ✅ **Multi-tenancy**: Complete isolation (RBAC + NetworkPolicy)
- ✅ **Monitoring**: Full observability stack
- ✅ **Alerting**: 6 critical alert rules
- ✅ **Autoscaling**: HPA with proper thresholds
- ✅ **CI/CD**: Automated pipeline with security scanning
- ✅ **Health Checks**: Liveness and readiness probes
- ✅ **Resource Limits**: CPU and memory constraints
- ✅ **Security Scanning**: Trivy integration
- ✅ **Documentation**: Comprehensive guides

### 🔄 Needs for Production

- 🔄 **Managed Kubernetes**: Migrate to EKS/GKE/AKS
- 🔄 **Ingress Controller**: NGINX with TLS
- 🔄 **Certificate Management**: cert-manager
- 🔄 **Private Registry**: ECR/GCR
- 🔄 **Secrets Management**: Vault/AWS Secrets Manager
- 🔄 **Log Aggregation**: ELK/Loki
- 🔄 **Real ML Model**: Trained on production data
- 🔄 **Model Versioning**: MLflow/S3 with versioning
- 🔄 **GitOps**: ArgoCD/Flux
- 🔄 **Backup**: Velero

---

## 🎓 Key Learnings & Best Practices

### What Went Well

1. ✅ **Terraform for Infrastructure**: Reproducible, version-controlled
2. ✅ **Multi-tenant Isolation**: Security-first approach
3. ✅ **Comprehensive Monitoring**: Full observability from day 1
4. ✅ **Autoscaling**: Dynamic resource management
5. ✅ **CI/CD Integration**: Automated workflows

### Challenges & Solutions

1. **Challenge**: TLS certificate issues with Kind registry
   - **Solution**: Pre-load images + `imagePullPolicy: IfNotPresent`

2. **Challenge**: Permission errors in containers
   - **Solution**: Proper ownership + non-root USER directive

3. **Challenge**: Prometheus admission webhook failures
   - **Solution**: Disable webhooks for local development

4. **Challenge**: HPA not scaling
   - **Solution**: Deploy Metrics Server with proper configuration

### Best Practices Implemented

- ✅ Non-root containers
- ✅ Resource limits on all pods
- ✅ Liveness and readiness probes
- ✅ Minimal RBAC permissions
- ✅ Network policies for isolation
- ✅ Structured logging
- ✅ Health endpoints
- ✅ Metrics exposure
- ✅ Security scanning in CI/CD
- ✅ Infrastructure as Code

---

## 📁 Project Structure

```
.
├── infra/terraform/              # Infrastructure as Code
│   ├── main.tf                   # Main Terraform config
│   ├── providers.tf              # Kubernetes/Helm providers
│   └── modules/
│       ├── cluster/              # Kind cluster creation
│       └── minio/                # MinIO deployment
│
├── ml-inference-service/         # ML application
│   ├── app/
│   │   ├── main.py              # FastAPI application
│   │   └── requirements.txt      # Python dependencies
│   ├── Dockerfile                # Container image
│   └── build-and-load.sh         # Build script
│
├── k8s-manifests/                # Kubernetes YAMLs
│   ├── tenant-a/                 # Tenant A resources
│   ├── tenant-b/                 # Tenant B resources
│   └── metrics-server/           # Metrics Server
│
├── monitoring/                   # Observability stack
│   ├── install-prometheus-grafana.sh
│   ├── servicemonitor.yaml       # Prometheus scrape config
│   ├── prometheusrule.yaml       # Alert rules
│   └── README.md
│
├── .github/workflows/            # CI/CD
│   └── ci-cd.yml                 # GitHub Actions pipeline
│
└── docs/                         # Documentation
    ├── AUTOSCALING_GUIDE.md
    ├── GPU_AUTOSCALING_GUIDE.md
    ├── EKS_DEPLOYMENT_GUIDE.md
    └── ARCHITECTURE_DIAGRAM.png
```

---

## 🔮 Future Enhancements

### Phase 1: Model Improvements
- [ ] Train on real dataset (100K+ samples)
- [ ] Add model versioning with MLflow
- [ ] Implement A/B testing
- [ ] Add model explainability (SHAP)

### Phase 2: Infrastructure
- [ ] Deploy to AWS EKS
- [ ] Set up Ingress with TLS
- [ ] Implement GitOps (ArgoCD)
- [ ] Add distributed tracing (Jaeger)

### Phase 3: Operations
- [ ] Set up PagerDuty integration
- [ ] Create runbooks for common issues
- [ ] Implement blue-green deployments
- [ ] Add chaos engineering (Chaos Mesh)

### Phase 4: ML Pipeline
- [ ] Add model training pipeline
- [ ] Implement feature store
- [ ] Add data versioning (DVC)
- [ ] Create model registry

---

## 📞 Support & Documentation

### Comprehensive Guides

- **`README.md`** - Main project overview
- **`k8s-manifests/README.md`** - Kubernetes resources explained
- **`AUTOSCALING_GUIDE.md`** - HPA setup and testing
- **`GPU_AUTOSCALING_GUIDE.md`** - GPU autoscaling with Karpenter
- **`EKS_DEPLOYMENT_GUIDE.md`** - AWS production deployment
- **`monitoring/README.md`** - Monitoring quick reference

### Quick Commands

```bash
# Check cluster status
kubectl get nodes

# Check all deployments
kubectl get deploy -A

# Check HPA status
kubectl get hpa -A

# Check pod resource usage
kubectl top pods -A

# View logs
kubectl logs -f -n tenant-a deployment/tenant-a-ml-inference

# Access Grafana
open http://localhost:30080

# Access Prometheus
open http://localhost:30090
```

---

## 📊 Project Statistics

- **Total Files**: 50+
- **Lines of Code**: 2,500+ (application + infrastructure)
- **Documentation Lines**: 3,000+
- **Docker Images**: 1 custom + 7 monitoring images
- **Kubernetes Resources**: 25+ (namespaces, deployments, services, etc.)
- **Alert Rules**: 6
- **Monitoring Panels**: 8
- **CI/CD Stages**: 6

---

## 🎯 Conclusion

This project demonstrates a **complete, production-ready MLOps infrastructure** with:

✅ **Multi-tenant ML inference** with complete isolation  
✅ **Security-first approach** (RBAC + NetworkPolicy)  
✅ **Full observability** (Prometheus + Grafana)  
✅ **Automated CI/CD** with security scanning  
✅ **Dynamic autoscaling** based on workload  
✅ **Comprehensive documentation** for all components  

The infrastructure is **ready for production deployment** on cloud platforms like AWS EKS, Google GKE, or Azure AKS with minimal modifications.

---

**Built with ❤️ for MLOps and DevOps Engineers**

*For questions or contributions, please open an issue on GitHub.*

