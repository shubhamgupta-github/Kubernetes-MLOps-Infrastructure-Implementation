# Architecture Diagram

## Complete System Architecture

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                        │
│                          Kubernetes Cluster (Kind - Local)                             │
│                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐ │
│  │                           Monitoring Namespace                                    │ │
│  │                                                                                   │ │
│  │   ┌─────────────────┐          ┌─────────────────┐         ┌──────────────────┐ │ │
│  │   │   Prometheus    │─────────▶│    Grafana      │◀────────│  AlertManager    │ │ │
│  │   │                 │          │                 │         │                  │ │ │
│  │   │  • Scrapes      │          │  • Dashboard    │         │  • Notifications │ │ │
│  │   │    metrics      │          │  • 8 panels     │         │  • Silencing     │ │ │
│  │   │  • Stores TSDB  │          │  • Alerting     │         │                  │ │ │
│  │   │  • Evaluates    │          │                 │         │                  │ │ │
│  │   │    alerts       │          │                 │         │                  │ │ │
│  │   └────────┬────────┘          └─────────────────┘         └──────────────────┘ │ │
│  │            │                           :30080                                    │ │
│  │            │                         (NodePort)                                  │ │
│  │            │                                                                     │ │
│  └────────────┼─────────────────────────────────────────────────────────────────────┘ │
│               │                                                                        │
│               │ (ServiceMonitor - auto-discovery)                                      │
│               │                                                                        │
│  ┌────────────▼─────────────────────┐      ┌──────────────────────────────────────┐  │
│  │    Tenant A Namespace            │      │    Tenant B Namespace                │  │
│  │                                  │      │                                      │  │
│  │  ┌────────────────────────────┐  │      │  ┌────────────────────────────────┐ │  │
│  │  │    HPA Controller          │  │      │  │    HPA Controller              │ │  │
│  │  │  • Min: 2 pods             │  │      │  │  • Min: 2 pods                 │ │  │
│  │  │  • Max: 10 pods            │  │      │  │  • Max: 10 pods                │ │  │
│  │  │  • Target: 50% CPU         │  │      │  │  • Target: 50% CPU             │ │  │
│  │  └────────────┬───────────────┘  │      │  └────────────┬───────────────────┘ │  │
│  │               │                   │      │               │                     │  │
│  │               ▼                   │      │               ▼                     │  │
│  │  ┌────────────────────────────┐  │      │  ┌────────────────────────────────┐ │  │
│  │  │   Deployment               │  │      │  │   Deployment                   │ │  │
│  │  │   (2-10 replicas)          │  │      │  │   (2-10 replicas)              │ │  │
│  │  │                            │  │      │  │                                │ │  │
│  │  │  ┌──────┐  ┌──────┐       │  │      │  │  ┌──────┐  ┌──────┐           │ │  │
│  │  │  │ Pod1 │  │ Pod2 │  ...  │  │      │  │  │ Pod1 │  │ Pod2 │  ...      │ │  │
│  │  │  │      │  │      │       │  │      │  │  │      │  │      │           │ │  │
│  │  │  │FastAPI  │FastAPI       │  │      │  │  │FastAPI  │FastAPI           │ │  │
│  │  │  │+ ML │  │+ ML │       │  │      │  │  │+ ML │  │+ ML │           │ │  │
│  │  │  │Model│  │Model│       │  │      │  │  │Model│  │Model│           │ │  │
│  │  │  └──────┘  └──────┘       │  │      │  │  └──────┘  └──────┘           │ │  │
│  │  └────────────┬───────────────┘  │      │  └────────────┬───────────────────┘ │  │
│  │               │                   │      │               │                     │  │
│  │               ▼                   │      │               ▼                     │  │
│  │  ┌────────────────────────────┐  │      │  ┌────────────────────────────────┐ │  │
│  │  │  Service (ClusterIP)       │  │      │  │  Service (ClusterIP)           │ │  │
│  │  │  tenant-a-ml-inference-svc │  │      │  │  tenant-b-ml-inference-svc     │ │  │
│  │  │  Port: 8000                │  │      │  │  Port: 8000                    │ │  │
│  │  └────────────────────────────┘  │      │  └────────────────────────────────┘ │  │
│  │                                  │      │                                      │  │
│  │  Security:                       │      │  Security:                           │  │
│  │  ✓ ServiceAccount                │      │  ✓ ServiceAccount                    │  │
│  │  ✓ RBAC Role                     │      │  ✓ RBAC Role                         │  │
│  │  ✓ RoleBinding                   │      │  ✓ RoleBinding                       │  │
│  │  ✓ NetworkPolicy                 │      │  ✓ NetworkPolicy                     │  │
│  │  ✓ Resource Limits               │      │  ✓ Resource Limits                   │  │
│  └──────────────────────────────────┘      └──────────────────────────────────────┘  │
│               ❌                                           ❌                          │
│               └────────── Network Isolated (via NetworkPolicy) ──────────────────┘   │
│                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐ │
│  │                           MinIO Namespace                                         │ │
│  │                                                                                   │ │
│  │   ┌─────────────────────────────────────────────────────────────────────────┐   │ │
│  │   │  MinIO Object Storage (S3-Compatible)                                   │   │ │
│  │   │                                                                          │   │ │
│  │   │  • API: http://minio-api:9000                                          │   │ │
│  │   │  • Console: http://minio-console:9001                                  │   │ │
│  │   │  • Buckets: models, datasets, artifacts                               │   │ │
│  │   │  • Persistent Storage (optional)                                        │   │ │
│  │   └─────────────────────────────────────────────────────────────────────────┘   │ │
│  └──────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐ │
│  │                         Metrics Server Namespace                                  │ │
│  │                                                                                   │ │
│  │   ┌─────────────────────────────────────────────────────────────────────────┐   │ │
│  │   │  Metrics Server                                                          │   │ │
│  │   │  • Collects resource metrics (CPU/Memory)                               │   │ │
│  │   │  • Provides data to HPA                                                 │   │ │
│  │   │  • Scrape interval: 60s                                                  │   │ │
│  │   └─────────────────────────────────────────────────────────────────────────┘   │ │
│  └──────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                        │
└───────────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ External Access
                                    ▼
                ┌───────────────────────────────────────────────────────────┐
                │               External Systems                             │
                │                                                            │
                │  ┌──────────────────────────────────────────────────────┐ │
                │  │  GitHub Actions (CI/CD Pipeline)                     │ │
                │  │                                                       │ │
                │  │  Trigger: Push to 'main' branch                      │ │
                │  │                                                       │ │
                │  │  Steps:                                              │ │
                │  │  1. Checkout code                                    │ │
                │  │  2. Build Docker image                               │ │
                │  │  3. Run Trivy security scan                          │ │
                │  │  4. Push to Docker Hub                               │ │
                │  │                                                       │ │
                │  │  Result: vendettaopppp/ml-inference-service:latest  │ │
                │  └──────────────────────────────────────────────────────┘ │
                │                                                            │
                │  ┌──────────────────────────────────────────────────────┐ │
                │  │  Docker Hub (Container Registry)                     │ │
                │  │  • Repository: vendettaopppp/ml-inference-service    │ │
                │  │  • Images tagged with git commit SHA                 │ │
                │  └──────────────────────────────────────────────────────┘ │
                │                                                            │
                │  ┌──────────────────────────────────────────────────────┐ │
                │  │  Developer Workstation                               │ │
                │  │  • kubectl port-forward (local testing)              │ │
                │  │  • Terraform (infrastructure management)             │ │
                │  └──────────────────────────────────────────────────────┘ │
                └───────────────────────────────────────────────────────────┘
```

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ML Inference Request Flow                        │
└─────────────────────────────────────────────────────────────────────────┘

1. Development Flow:
   ┌────────────┐
   │ Developer  │
   └─────┬──────┘
         │ git push
         ▼
   ┌────────────────┐
   │ GitHub Actions │
   └─────┬──────────┘
         │ build + scan + push
         ▼
   ┌────────────────┐
   │  Docker Hub    │
   └─────┬──────────┘
         │ pull
         ▼
   ┌────────────────┐
   │  Kind Cluster  │
   └────────────────┘

2. Prediction Request Flow:
   ┌────────────┐
   │   Client   │
   └─────┬──────┘
         │ HTTP POST /predict
         ▼
   ┌────────────────────────┐
   │ kubectl port-forward   │
   └─────┬──────────────────┘
         │
         ▼
   ┌────────────────────────┐
   │  Service (ClusterIP)   │
   └─────┬──────────────────┘
         │ Load balance
         ▼
   ┌────────────────────────┐
   │  Pod 1, 2, 3... (HPA)  │
   └─────┬──────────────────┘
         │
         ▼
   ┌────────────────────────┐
   │  FastAPI Application   │
   └─────┬──────────────────┘
         │
         ▼
   ┌────────────────────────┐
   │  ML Model (in-memory)  │
   │  • Vectorizer          │
   │  • Naive Bayes         │
   └─────┬──────────────────┘
         │
         ▼
   ┌────────────────────────┐
   │  JSON Response         │
   │  {                     │
   │    "prediction": "...",│
   │    "confidence": 0.87  │
   │  }                     │
   └────────────────────────┘

3. Monitoring Flow:
   ┌────────────────────────┐
   │  ML Inference Pods     │
   │  /metrics endpoint     │
   └─────┬──────────────────┘
         │ scrape every 30s
         ▼
   ┌────────────────────────┐
   │  ServiceMonitor (CRD)  │
   └─────┬──────────────────┘
         │ configure scraping
         ▼
   ┌────────────────────────┐
   │  Prometheus            │
   │  • Store metrics       │
   │  • Evaluate alerts     │
   └─────┬──────────────────┘
         │ query
         ▼
   ┌────────────────────────┐
   │  Grafana Dashboard     │
   │  • Visualize metrics   │
   │  • Show alerts         │
   └────────────────────────┘

4. Autoscaling Flow:
   ┌────────────────────────┐
   │  Metrics Server        │
   │  Collects CPU/Memory   │
   └─────┬──────────────────┘
         │ provides metrics
         ▼
   ┌────────────────────────┐
   │  HPA Controller        │
   │  Monitors CPU usage    │
   └─────┬──────────────────┘
         │ CPU > 50%
         ▼
   ┌────────────────────────┐
   │  Scale Deployment      │
   │  2 → 4 → 6 → 8 → 10    │
   └────────────────────────┘
```

## Component Interactions

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Component Relationships                         │
└─────────────────────────────────────────────────────────────────────┘

Terraform
  ├── Creates Kind Cluster
  │   └── 5 nodes (1 control plane + 4 workers)
  └── Deploys MinIO
      └── Namespace + Deployment + Service

Kubernetes Manifests
  ├── tenant-a/
  │   ├── Namespace ──┐
  │   ├── ServiceAccount │
  │   ├── Role         │─────▶ RBAC Isolation
  │   ├── RoleBinding  │
  │   ├── Deployment ──┼────▶ ML Inference Pods
  │   ├── Service     ─┤
  │   ├── NetworkPolicy ├────▶ Network Isolation
  │   └── HPA ─────────┼────▶ Autoscaling
  │                    │
  └── tenant-b/        │
      └── (same structure)

CI/CD Pipeline
  └── GitHub Actions
      ├── Build ─────▶ Docker Image
      ├── Scan ──────▶ Trivy Report
      └── Push ──────▶ Docker Hub

Monitoring Stack
  ├── ServiceMonitor ──▶ Configures Prometheus
  ├── PrometheusRule ──▶ Defines Alerts
  ├── Prometheus ──────▶ Collects Metrics
  └── Grafana ─────────▶ Visualizes Data
```

## Security Boundaries

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Security Layers                              │
└─────────────────────────────────────────────────────────────────────┘

Layer 1: Namespace Isolation
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  tenant-a    │  │  tenant-b    │  │  monitoring  │
│  namespace   │  │  namespace   │  │  namespace   │
└──────────────┘  └──────────────┘  └──────────────┘
      ↑                ↑                    ↑
      └────────────────┴────────────────────┘
               Logical Boundary

Layer 2: RBAC (Role-Based Access Control)
┌─────────────────────────────────────────┐
│  ServiceAccount: tenant-a-ml-inference  │
│  Role: minimal permissions (get, list)  │
│  RoleBinding: binds role to SA          │
└─────────────────────────────────────────┘
           ↓
   Can ONLY access tenant-a namespace
           ↓
   ❌ Cannot access tenant-b

Layer 3: NetworkPolicy
┌─────────────────────────────────────────┐
│  Ingress: Only from same namespace      │
│  Egress: DNS + external APIs only       │
└─────────────────────────────────────────┘
           ↓
   tenant-a pods ❌ cannot reach tenant-b pods

Layer 4: Resource Limits
┌─────────────────────────────────────────┐
│  CPU Limit: 500m per pod                │
│  Memory Limit: 512Mi per pod            │
└─────────────────────────────────────────┘
           ↓
   Prevents resource starvation

Layer 5: Container Security
┌─────────────────────────────────────────┐
│  Non-root user (UID 1000)               │
│  Read-only root filesystem (optional)   │
│  Drop all capabilities                  │
└─────────────────────────────────────────┘
```

---

## How to Create as PNG/Draw.io

### Option 1: Using Draw.io (Recommended)

1. Go to https://app.diagrams.net/
2. Create new diagram
3. Use these shapes:
   - **Rectangles**: For namespaces, pods, services
   - **Cylinders**: For databases (MinIO, Prometheus)
   - **Clouds**: For external services (GitHub, Docker Hub)
   - **Dashed lines**: For logical connections
   - **Solid lines**: For network traffic
   - **Red X**: For blocked connections

4. Color scheme:
   - **Blue**: Kubernetes components
   - **Green**: Monitoring stack
   - **Orange**: ML inference services
   - **Gray**: External services
   - **Red**: Security boundaries

5. Export as PNG: File → Export as → PNG

### Option 2: Using Lucidchart

1. Go to https://www.lucidchart.com/
2. Use Kubernetes shape library
3. Follow same structure as above
4. Export as PNG or PDF

### Option 3: Using Mermaid (Code-based)

Copy the Mermaid code below and paste into:
- https://mermaid.live/
- Or any Markdown viewer that supports Mermaid

```mermaid
graph TB
    subgraph External["External Systems"]
        GH[GitHub Actions<br/>CI/CD]
        DH[Docker Hub<br/>Registry]
        Dev[Developer<br/>Workstation]
    end

    subgraph K8s["Kubernetes Cluster (Kind)"]
        subgraph Mon["monitoring namespace"]
            Prom[Prometheus<br/>Metrics Collection]
            Graf[Grafana<br/>Dashboard]
            AM[AlertManager<br/>Notifications]
        end

        subgraph TenantA["tenant-a namespace"]
            HPA_A[HPA<br/>2-10 pods]
            Deploy_A[Deployment<br/>ML Inference]
            Svc_A[Service<br/>ClusterIP]
            RBAC_A[RBAC + NetworkPolicy]
        end

        subgraph TenantB["tenant-b namespace"]
            HPA_B[HPA<br/>2-10 pods]
            Deploy_B[Deployment<br/>ML Inference]
            Svc_B[Service<br/>ClusterIP]
            RBAC_B[RBAC + NetworkPolicy]
        end

        subgraph Storage["minio namespace"]
            MinIO[MinIO<br/>Object Storage]
        end

        MS[Metrics Server<br/>Resource Metrics]
    end

    Dev -->|kubectl| K8s
    GH -->|build + scan| DH
    DH -->|pull image| K8s

    Prom -->|scrape| Deploy_A
    Prom -->|scrape| Deploy_B
    Prom --> Graf
    Prom --> AM

    HPA_A -->|scale| Deploy_A
    HPA_B -->|scale| Deploy_B
    MS -->|metrics| HPA_A
    MS -->|metrics| HPA_B

    Deploy_A --> Svc_A
    Deploy_B --> Svc_B

    Deploy_A -.x.-|blocked| Deploy_B

    style Mon fill:#e1f5e1
    style TenantA fill:#e1e5f5
    style TenantB fill:#f5e1e1
    style Storage fill:#f5f5e1
    style External fill:#f0f0f0
```

---

## Key Architectural Decisions

### 1. Why Kind (Kubernetes in Docker)?
- **Local Development**: No cloud costs
- **Fast Iteration**: Quick cluster creation/deletion
- **Reproducible**: Works on any machine
- **Production-like**: Real Kubernetes, not mocked

### 2. Why Multi-Tenant Architecture?
- **Isolation**: Security boundary between tenants
- **Scalability**: Each tenant scales independently
- **Cost Efficiency**: Shared infrastructure
- **Compliance**: Separate workload boundaries

### 3. Why Helm for Monitoring?
- **Battle-tested**: kube-prometheus-stack is industry standard
- **Pre-configured**: Dashboards and alerts included
- **Easy Updates**: Simple version management
- **Community Support**: Large user base

### 4. Why FastAPI for ML Serving?
- **Performance**: Async support, fast startup
- **Developer Experience**: Auto-generated docs
- **Type Safety**: Pydantic validation
- **Production Ready**: Used by Netflix, Uber

### 5. Why NetworkPolicy + RBAC?
- **Defense in Depth**: Multiple security layers
- **Zero Trust**: Explicit allow, implicit deny
- **Compliance**: Meets security standards
- **Auditability**: All access is logged

---

This architecture diagram can be saved as PNG and included in your project documentation!

