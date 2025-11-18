# MinIO Terraform Module

This module deploys MinIO object storage on Kubernetes using Terraform.

## Features

- ✅ Automated namespace creation
- ✅ Deployment with configurable replicas
- ✅ Service exposure (ClusterIP, NodePort, or LoadBalancer)
- ✅ Optional persistent storage
- ✅ Configurable credentials
- ✅ Both API (9000) and Console (9001) ports exposed

## Usage

```hcl
module "minio" {
  source = "./modules/minio"

  namespace          = "minio"
  replicas           = 1
  minio_image        = "minio/minio:latest"
  root_user          = "admin"
  root_password      = "admin123"
  service_type       = "NodePort"
  enable_persistence = false
  storage_size       = "10Gi"
  storage_class_name = "standard"
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| namespace | Kubernetes namespace for MinIO | string | "minio" | no |
| replicas | Number of MinIO replicas | number | 1 | no |
| minio_image | MinIO Docker image | string | "minio/minio:latest" | no |
| root_user | MinIO root user | string | "admin" | no |
| root_password | MinIO root password | string | "admin123" | no |
| service_type | Kubernetes service type | string | "ClusterIP" | no |
| enable_persistence | Enable persistent storage | bool | false | no |
| storage_size | Size of persistent storage | string | "10Gi" | no |
| storage_class_name | Storage class name for PVC | string | "standard" | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | MinIO namespace |
| service_name | MinIO service name |
| api_endpoint | MinIO API endpoint (internal) |
| console_endpoint | MinIO Console endpoint (internal) |

## Accessing MinIO

### Within the cluster
- **API**: `minio.minio.svc.cluster.local:9000`
- **Console**: `minio.minio.svc.cluster.local:9001`

### From outside the cluster

#### Option 1: Port Forward
```bash
kubectl port-forward -n minio svc/minio 9000:9000 9001:9001
```

Then access:
- **API**: http://localhost:9000
- **Console**: http://localhost:9001

#### Option 2: NodePort (if service_type = "NodePort")
```bash
kubectl get svc -n minio minio
```

Access via `http://<node-ip>:<node-port>`

#### Option 3: LoadBalancer (if service_type = "LoadBalancer")
```bash
kubectl get svc -n minio minio
```

Access via the external IP provided by your cloud provider.

## Persistent Storage

To enable persistent storage:

```hcl
module "minio" {
  source = "./modules/minio"
  
  enable_persistence = true
  storage_size       = "20Gi"
  storage_class_name = "standard"  # or your cluster's storage class
}
```

## Troubleshooting

### ImagePullBackOff / TLS Certificate Errors

If you see errors like `x509: certificate signed by unknown authority` when deploying with Terraform:

**Solution 1: Pre-load the image (Recommended for Kind clusters)**

```powershell
# On Windows
cd infra/terraform/modules/minio
.\preload-image.ps1 -ClusterName "mlops-kind-cluster"
```

```bash
# On Linux/Mac
cd infra/terraform/modules/minio
./preload-image.sh mlops-kind-cluster
```

**Solution 2: Use IfNotPresent policy** (Already configured)

```hcl
module "minio" {
  source = "./modules/minio"
  image_pull_policy = "IfNotPresent"  # Avoids unnecessary pulls
}
```

**Solution 3: Wait for cluster to stabilize**

The cluster module now includes automatic wait conditions. If issues persist:
1. Create the cluster first: `terraform apply -target=module.cluster`
2. Wait 1-2 minutes
3. Deploy MinIO: `terraform apply`

**Why does this happen?**

Kind clusters need time after creation for:
- Node networking to stabilize
- Docker registry certificates to be configured
- System pods (CoreDNS, CNI) to be ready

Manual `kubectl apply` works because you're applying after the cluster has stabilized.

## Security Considerations

⚠️ **Important**: 
- Change default credentials in production
- Consider using Kubernetes secrets for credentials
- Use TLS/SSL for production deployments
- Restrict network access using NetworkPolicies

## Example: Production Configuration

```hcl
module "minio" {
  source = "./modules/minio"

  namespace          = "minio"
  replicas           = 1
  minio_image        = "minio/minio:RELEASE.2024-01-01T00-00-00Z"  # Use specific version
  root_user          = var.minio_root_user      # From variables
  root_password      = var.minio_root_password  # From variables
  service_type       = "LoadBalancer"
  enable_persistence = true
  storage_size       = "100Gi"
  storage_class_name = "fast-ssd"
}
```

