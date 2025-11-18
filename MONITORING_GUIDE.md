# Monitoring & Alerting Guide

Complete guide for Prometheus + Grafana monitoring stack for the ML Inference Service.

## Overview

This implementation provides:
- ✅ **Prometheus** - Metrics collection and alerting
- ✅ **Grafana** - Visualization dashboards
- ✅ **ServiceMonitors** - Automatic service discovery
- ✅ **Alert Rules** - High latency, pod restarts, errors
- ✅ **Dashboard** - Request/latency metrics for both tenants

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                         │
│                                                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  tenant-a & tenant-b Namespaces                     │    │
│  │  ┌─────────────────────────────────────────┐       │    │
│  │  │  ML Inference Pods                      │       │    │
│  │  │  • Expose /metrics endpoint             │       │    │
│  │  │  • FastAPI metrics                      │       │    │
│  │  │  • Request count, latency, errors       │       │    │
│  │  └─────────────────────────────────────────┘       │    │
│  └─────────────────────────────────────────────────────┘    │
│                           ↓                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ServiceMonitors (CRD)                              │    │
│  │  • Discovers services with labels                  │    │
│  │  • Configures scrape intervals                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                           ↓                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Prometheus                                          │    │
│  │  • Scrapes metrics every 30s                        │    │
│  │  • Stores time-series data                          │    │
│  │  • Evaluates alert rules                            │    │
│  │  • Sends alerts to AlertManager                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                           ↓                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Grafana                                             │    │
│  │  • Queries Prometheus                               │    │
│  │  • Renders dashboards                               │    │
│  │  • Shows real-time metrics                          │    │
│  └─────────────────────────────────────────────────────┘    │
│                           ↓                                    │
│                   http://localhost:30080                      │
└──────────────────────────────────────────────────────────────┘
```

---

## Quick Deployment

### Prerequisites

1. **Helm installed**:
   ```bash
   # Windows (Chocolatey)
   choco install kubernetes-helm
   
   # Linux
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   
   # Mac
   brew install helm
   ```

2. **ML Inference service running** in tenant-a and tenant-b

---

### Step 1: Install Prometheus + Grafana

**Windows:**
```powershell
cd monitoring
.\install-prometheus-grafana.ps1
```

**Linux/Mac:**
```bash
cd monitoring
chmod +x install-prometheus-grafana.sh
./install-prometheus-grafana.sh
```

**What it does:**
- Installs kube-prometheus-stack via Helm
- Creates monitoring namespace
- Deploys Prometheus, Grafana, AlertManager
- Configures NodePort access (30080, 30090)
- Sets Grafana password to "admin"

**Duration**: 2-3 minutes

---

### Step 2: Deploy ServiceMonitors

```bash
kubectl apply -f monitoring/servicemonitor.yaml
```

**What it does:**
- Configures Prometheus to scrape ML inference /metrics endpoints
- Scrapes tenant-a and tenant-b every 30 seconds
- Autodiscovers services with matching labels

---

### Step 3: Deploy Alert Rules

```bash
kubectl apply -f monitoring/prometheusrule.yaml
```

**What it does:**
- Creates 6 alert rules:
  1. High latency (>5s)
  2. Pod restarts (>3 in 10min)
  3. High error rate (>5%)
  4. Pod not ready
  5. High CPU usage (>80%)
  6. High memory usage (>90%)

---

### Step 4: Import Grafana Dashboard

1. **Access Grafana**: http://localhost:30080
2. **Login**:
   - Username: `admin`
   - Password: `admin`
3. **Import Dashboard**:
   - Click "+" → "Import"
   - Click "Upload JSON file"
   - Select `monitoring/dashboard.json`
   - Click "Load"
   - Select "Prometheus" as data source
   - Click "Import"

---

## Accessing the Stack

### Grafana (Dashboards)

```bash
# Access URL
http://localhost:30080

# Credentials
Username: admin
Password: admin
```

**What you'll see:**
- ML Inference Service Dashboard
- Request rate per tenant
- Latency (p95, p50)
- Running pods
- CPU/Memory usage
- Pod restarts

### Prometheus (Metrics & Alerts)

```bash
# Access URL
http://localhost:30090

# No authentication required
```

**What you can do:**
- Query metrics manually
- View active alerts
- Check targets (scrape status)
- Explore time-series data

### AlertManager (Alert Management)

```bash
# Port forward to access
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093

# Access URL
http://localhost:9093
```

**What you can do:**
- View active alerts
- Silence alerts
- Configure alert routes

---

## Dashboard Panels Explained

### 1. Request Rate per Tenant

**Query:**
```promql
sum(rate(fastapi_requests_total{namespace=~"tenant-a|tenant-b"}[5m])) by (namespace)
```

**Shows**: Requests per second for each tenant

**Use case**: Identify traffic patterns, compare tenant load

---

### 2. Request Latency (p95 & p50)

**Query (p95):**
```promql
histogram_quantile(0.95, sum(rate(fastapi_request_duration_seconds_bucket{namespace=~"tenant-a|tenant-b"}[5m])) by (namespace, le))
```

**Shows**: 95th and 50th percentile response times

**Use case**: Monitor service performance, detect slowdowns

**Thresholds:**
- Green: < 1s
- Yellow: 1-5s
- Red: > 5s

---

### 3. Running Pods

**Query:**
```promql
count(kube_pod_status_phase{namespace="tenant-a", pod=~".*ml-inference.*", phase="Running"})
```

**Shows**: Number of healthy pods per tenant

**Use case**: Ensure high availability, detect pod failures

---

### 4. Total Pod Restarts

**Query:**
```promql
sum(kube_pod_container_status_restarts_total{namespace=~"tenant-a|tenant-b", pod=~".*ml-inference.*"})
```

**Shows**: Cumulative restart count across all pods

**Use case**: Detect crashloop issues, stability problems

**Thresholds:**
- Green: 0 restarts
- Yellow: 1-2 restarts
- Red: 3+ restarts

---

### 5. Average CPU Usage

**Query:**
```promql
sum(rate(container_cpu_usage_seconds_total{namespace=~"tenant-a|tenant-b", pod=~".*ml-inference.*"}[5m])) / sum(kube_pod_container_resource_limits{resource="cpu", namespace=~"tenant-a|tenant-b", pod=~".*ml-inference.*"})
```

**Shows**: CPU usage as percentage of limit

**Use case**: Monitor resource utilization, trigger HPA

**Thresholds:**
- Green: < 70%
- Yellow: 70-90%
- Red: > 90%

---

### 6. Memory Usage

**Query:**
```promql
sum(container_memory_working_set_bytes{namespace=~"tenant-a|tenant-b", pod=~".*ml-inference.*"}) by (namespace, pod)
```

**Shows**: Memory consumption per pod

**Use case**: Detect memory leaks, optimize allocation

---

### 7. CPU Usage per Pod

**Query:**
```promql
sum(rate(container_cpu_usage_seconds_total{namespace=~"tenant-a|tenant-b", pod=~".*ml-inference.*"}[5m])) by (namespace, pod) * 100
```

**Shows**: Detailed CPU usage per pod

**Use case**: Identify hot spots, balance load

---

## Alert Rules Explained

### 1. MLInferenceHighLatency

**Triggers when**: 95th percentile latency > 5 seconds for 2 minutes

**Severity**: Warning

**Query:**
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="ml-inference"}[5m])) > 5
```

**What to do:**
- Check pod resource usage
- Review application logs
- Scale up if CPU/memory constrained
- Optimize model inference

---

### 2. MLInferencePodRestarts

**Triggers when**: More than 3 restarts in 10 minutes

**Severity**: Critical

**Query:**
```promql
rate(kube_pod_container_status_restarts_total{namespace=~"tenant-a|tenant-b", pod=~".*ml-inference.*"}[10m]) * 600 > 3
```

**What to do:**
- Check pod logs: `kubectl logs -n tenant-a <pod>`
- Review liveness/readiness probes
- Check resource limits
- Fix application bugs causing crashes

---

### 3. MLInferenceHighErrorRate

**Triggers when**: Error rate > 5% for 5 minutes

**Severity**: Warning

**Query:**
```promql
(sum(rate(http_requests_total{job="ml-inference", status=~"5.."}[5m])) by (namespace, pod) / sum(rate(http_requests_total{job="ml-inference"}[5m])) by (namespace, pod)) * 100 > 5
```

**What to do:**
- Review application logs
- Check for model errors
- Validate input data
- Review recent code changes

---

### 4. MLInferencePodNotReady

**Triggers when**: Pod not ready for 5 minutes

**Severity**: Warning

**Query:**
```promql
kube_pod_status_ready{namespace=~"tenant-a|tenant-b", pod=~".*ml-inference.*", condition="false"} == 1
```

**What to do:**
- Check readiness probe: `kubectl describe pod -n tenant-a <pod>`
- Review pod events
- Check if /ready endpoint is working

---

### 5. MLInferenceHighCPU

**Triggers when**: CPU usage > 0.8 cores for 10 minutes

**Severity**: Warning

**Query:**
```promql
sum(rate(container_cpu_usage_seconds_total{namespace=~"tenant-a|tenant-b", pod=~".*ml-inference.*"}[5m])) by (namespace, pod) > 0.8
```

**What to do:**
- Review if this is expected (high load)
- Consider scaling up (HPA should handle this)
- Increase CPU limits if needed
- Optimize code for CPU efficiency

---

### 6. MLInferenceHighMemory

**Triggers when**: Memory usage > 90% of limit for 5 minutes

**Severity**: Critical

**Query:**
```promql
sum(container_memory_working_set_bytes{namespace=~"tenant-a|tenant-b", pod=~".*ml-inference.*"}) by (namespace, pod) / sum(container_spec_memory_limit_bytes{namespace=~"tenant-a|tenant-b", pod=~".*ml-inference.*"}) by (namespace, pod) > 0.9
```

**What to do:**
- Check for memory leaks
- Increase memory limits
- Review model size
- Optimize data processing

---

## Viewing Alerts

### In Prometheus

1. Go to http://localhost:30090
2. Click "Alerts" in top menu
3. See all configured rules and their status

**States:**
- **Inactive** (Green): No issue
- **Pending** (Yellow): Condition met but waiting for duration
- **Firing** (Red): Alert active!

### In Grafana

1. Go to http://localhost:30080
2. Click "Alerting" → "Alert Rules"
3. See Prometheus alerts

You can also add alert panels to dashboards.

---

## Testing Alerts

### Test High Latency Alert

Generate slow requests:

```bash
# Port forward
kubectl port-forward -n tenant-a svc/tenant-a-ml-inference-svc 8000:8000

# Send slow requests (if you add sleep in the app)
for i in {1..100}; do
  curl -X POST http://localhost:8000/predict \
    -H "Content-Type: application/json" \
    -d '{"text": "test"}' &
done
```

Wait 2 minutes, check Prometheus alerts.

### Test Pod Restart Alert

Kill a pod multiple times:

```bash
# Delete pod (it will restart)
kubectl delete pod -n tenant-a -l app=ml-inference --force

# Wait 30 seconds
sleep 30

# Repeat 3 more times
kubectl delete pod -n tenant-a -l app=ml-inference --force
```

Wait 1 minute, check alerts.

---

## Querying Prometheus Manually

Access Prometheus: http://localhost:30090

### Useful Queries

**Request rate:**
```promql
rate(fastapi_requests_total{namespace="tenant-a"}[5m])
```

**Error rate:**
```promql
rate(fastapi_requests_total{namespace="tenant-a",status=~"5.."}[5m])
```

**Average latency:**
```promql
rate(fastapi_request_duration_seconds_sum[5m]) / rate(fastapi_request_duration_seconds_count[5m])
```

**Pod memory:**
```promql
container_memory_working_set_bytes{namespace="tenant-a"}
```

**Pod CPU:**
```promql
rate(container_cpu_usage_seconds_total{namespace="tenant-a"}[5m])
```

---

## Troubleshooting

### Metrics not showing in Grafana

**Check Prometheus targets:**
```bash
# Access Prometheus
http://localhost:30090

# Go to Status → Targets
# Look for ml-inference endpoints
```

**If targets are down:**
```bash
# Check ServiceMonitor
kubectl get servicemonitor -A

# Check if service exists and has correct labels
kubectl get svc -n tenant-a -l app=ml-inference

# Check pod has /metrics endpoint
kubectl port-forward -n tenant-a <pod> 8000:8000
curl http://localhost:8000/metrics
```

### Dashboard shows "No Data"

**Check data source:**
1. Grafana → Configuration → Data Sources
2. Verify "Prometheus" is configured
3. URL should be: `http://prometheus-kube-prometheus-prometheus.monitoring:9090`
4. Click "Save & Test"

### Alerts not firing

**Check alert rules:**
```bash
# View PrometheusRule
kubectl get prometheusrule -n monitoring

# Check Prometheus picked them up
# Go to http://localhost:30090 → Alerts
```

**If rules missing:**
```bash
# Reapply
kubectl apply -f monitoring/prometheusrule.yaml

# Wait 1 minute for Prometheus to reload
```

---

## Performance Impact

### Resource Usage

**Prometheus:**
- CPU: ~200-500m
- Memory: ~500MB - 2GB (grows with data)
- Storage: ~1GB per day (default retention: 15 days)

**Grafana:**
- CPU: ~50-100m
- Memory: ~200-300MB

**ServiceMonitors:**
- Negligible (CRDs only)

**Total overhead**: ~1-2GB RAM, ~0.5 CPU cores

### Scrape Impact

- 30s interval per target
- ~10-20 metrics per scrape
- Minimal impact on ML service (<1ms per scrape)

---

## Best Practices

### 1. Set Appropriate Alert Thresholds

Adjust based on your SLAs:

```yaml
# For faster services
averageUtilization: 1  # Alert at 1 second

# For batch services
averageUtilization: 30  # Alert at 30 seconds
```

### 2. Use Alert Grouping

Group related alerts to avoid spam:

```yaml
# In AlertManager config
route:
  group_by: ['namespace', 'alertname']
  group_wait: 30s
  group_interval: 5m
```

### 3. Set Up Notifications

Configure AlertManager to send notifications:

```yaml
receivers:
  - name: 'slack'
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK'
        channel: '#alerts'
  - name: 'email'
    email_configs:
      - to: 'team@company.com'
```

### 4. Create Custom Dashboards

Create dashboards for:
- Business metrics (predictions per day, accuracy)
- Cost metrics (resource usage, efficiency)
- User metrics (tenant-specific views)

### 5. Regular Review

- Weekly: Review alert history
- Monthly: Tune alert thresholds
- Quarterly: Optimize dashboard layout

---

## Cleanup

To remove monitoring stack:

```bash
# Uninstall Helm release
helm uninstall prometheus -n monitoring

# Delete namespace
kubectl delete namespace monitoring

# Delete CRDs (optional)
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
```

---

## Summary

✅ **Deployed**: Prometheus + Grafana + AlertManager  
✅ **Dashboard**: Request rate, latency, pod status, resource usage  
✅ **Alerts**: High latency, pod restarts, errors, resource limits  
✅ **Access**: http://localhost:30080 (Grafana), http://localhost:30090 (Prometheus)  
✅ **Real-time**: 10-second refresh, 30-second scrape interval  

**Result**: Complete observability for ML inference service! 🎉

---

## Next Steps

1. Configure AlertManager notifications (Slack/Email)
2. Add custom business metrics to ML service
3. Create per-tenant dashboards
4. Set up log aggregation (ELK/Loki)
5. Add distributed tracing (Jaeger)
6. Integrate with on-call rotation (PagerDuty)

For production deployment, see `EKS_DEPLOYMENT_GUIDE.md` for cloud-specific monitoring setup.

