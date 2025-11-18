# Monitoring Stack - Quick Reference

Quick guide for deploying and using Prometheus + Grafana monitoring.

## 🚀 Quick Start (5 minutes)

### 1. Install Stack

**Windows:**
```powershell
.\install-prometheus-grafana.ps1
```

**Linux/Mac:**
```bash
chmod +x install-prometheus-grafana.sh
./install-prometheus-grafana.sh
```

### 2. Deploy Monitors & Alerts

```bash
kubectl apply -f servicemonitor.yaml
kubectl apply -f prometheusrule.yaml
```

### 3. Access Grafana

1. Go to: http://localhost:30080
2. Login: `admin` / `admin`
3. Import dashboard:
   - Click "+" → "Import"
   - Upload `dashboard.json`
   - Select "Prometheus" data source
   - Click "Import"

✅ **Done!** You now have full monitoring.

---

## 📊 Access URLs

| Service    | URL                         | Credentials      |
|------------|-----------------------------|------------------|
| Grafana    | http://localhost:30080      | admin/admin      |
| Prometheus | http://localhost:30090      | None             |

---

## 📈 What You Get

### Dashboard Panels:
1. **Request Rate** - Requests/sec per tenant
2. **Latency** - p95 & p50 response times
3. **Running Pods** - Health status
4. **Pod Restarts** - Stability tracking
5. **CPU Usage** - Resource utilization
6. **Memory Usage** - Memory consumption

### Alert Rules:
1. **High Latency** - Response time > 5s
2. **Pod Restarts** - More than 3 restarts in 10min
3. **High Error Rate** - > 5% errors
4. **Pod Not Ready** - Pod unhealthy > 5min
5. **High CPU** - CPU > 80% for 10min
6. **High Memory** - Memory > 90% for 5min

---

## 🔍 Quick Checks

### Check Prometheus is scraping:

```bash
# Access Prometheus
http://localhost:30090

# Go to Status → Targets
# Should see tenant-a and tenant-b endpoints
```

### Check metrics are being collected:

```bash
# Port forward to ML service
kubectl port-forward -n tenant-a svc/tenant-a-ml-inference-svc 8000:8000

# Get metrics
curl http://localhost:8000/metrics
```

### Check alerts:

```bash
# Access Prometheus
http://localhost:30090

# Click "Alerts" in top menu
```

---

## 🧪 Test Monitoring

### Generate traffic:

```bash
# Port forward
kubectl port-forward -n tenant-a svc/tenant-a-ml-inference-svc 8000:8000

# Send requests
for i in {1..100}; do
  curl -X POST http://localhost:8000/predict \
    -H "Content-Type: application/json" \
    -d '{"text": "This is a test"}' &
done
```

**Then watch dashboard update in real-time!**

---

## 📁 Files Explained

| File                            | Purpose                               |
|---------------------------------|---------------------------------------|
| `install-prometheus-grafana.sh` | Installs Prometheus + Grafana via Helm|
| `install-prometheus-grafana.ps1`| Windows version of install script     |
| `servicemonitor.yaml`           | Configures metric scraping            |
| `prometheusrule.yaml`           | Defines alert rules                   |
| `dashboard.json`                | Grafana dashboard definition          |

---

## 🛠️ Common Commands

### View all monitoring resources:

```bash
kubectl get all -n monitoring
```

### View ServiceMonitors:

```bash
kubectl get servicemonitor -A
```

### View PrometheusRules:

```bash
kubectl get prometheusrule -n monitoring
```

### View alerts (CLI):

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Then go to http://localhost:9090/alerts
```

### Restart Grafana:

```bash
kubectl rollout restart deployment prometheus-grafana -n monitoring
```

### Restart Prometheus:

```bash
kubectl delete pod -n monitoring -l app.kubernetes.io/name=prometheus
```

---

## 🐛 Troubleshooting

### "No data" in Grafana dashboard:

1. Check Prometheus targets are UP:
   ```bash
   http://localhost:30090 → Status → Targets
   ```

2. Verify ServiceMonitor exists:
   ```bash
   kubectl get servicemonitor -n tenant-a
   ```

3. Check service labels match:
   ```bash
   kubectl get svc -n tenant-a -l app=ml-inference --show-labels
   ```

### Alerts not showing:

1. Check PrometheusRule is created:
   ```bash
   kubectl get prometheusrule -n monitoring
   ```

2. View Prometheus logs:
   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus
   ```

3. Reapply rules:
   ```bash
   kubectl apply -f prometheusrule.yaml
   ```

### Can't access Grafana:

1. Check pod is running:
   ```bash
   kubectl get pods -n monitoring | grep grafana
   ```

2. Check service:
   ```bash
   kubectl get svc -n monitoring | grep grafana
   ```

3. Port forward manually:
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
   # Access at http://localhost:3000
   ```

---

## 🧹 Cleanup

To remove everything:

```bash
# Uninstall Helm release
helm uninstall prometheus -n monitoring

# Delete namespace
kubectl delete namespace monitoring

# Delete ServiceMonitors
kubectl delete servicemonitor -n tenant-a tenant-a-ml-inference
kubectl delete servicemonitor -n tenant-b tenant-b-ml-inference
```

---

## 📚 More Information

For detailed documentation, see: `../MONITORING_GUIDE.md`

---

## ✅ Verification Checklist

- [ ] Helm installed
- [ ] `helm repo add prometheus-community` successful
- [ ] `helm install prometheus` successful
- [ ] Grafana accessible at http://localhost:30080
- [ ] Prometheus accessible at http://localhost:30090
- [ ] ServiceMonitors created in tenant-a and tenant-b
- [ ] PrometheusRule created in monitoring namespace
- [ ] Dashboard imported in Grafana
- [ ] Targets showing as UP in Prometheus
- [ ] Dashboard panels showing data
- [ ] Alerts visible in Prometheus

**All checked? You're ready to go! 🎉**

