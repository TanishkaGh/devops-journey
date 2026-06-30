# Monitoring — Day 1
### Prometheus + Grafana Setup with Helm

---

## Why Monitoring Exists

You have a Kubernetes cluster running your app, self-healing, scaling, rolling out updates. But how do you actually know if everything is healthy right now?

- Is CPU usage too high?
- Is memory about to run out?
- Are pods crashing repeatedly?
- Is the app responding slowly?
- Did something break at 3am while you were asleep?

Without monitoring you find out when a customer complains. With monitoring you find out the second it happens.

---

## The Two Tools

**Prometheus** — collects and stores metrics. Constantly asks your app and cluster "how are you doing?" every few seconds and stores answers as numbers over time (time-series data). CPU usage, memory usage, request count, error rate — all stored with timestamps.

**Grafana** — takes that data and turns it into visual dashboards. Graphs, charts, color-coded alerts. Prometheus stores numbers, Grafana makes them human-readable.

**Analogy:** Prometheus is a fitness tracker constantly logging heart rate, steps, sleep. Grafana is the app that turns that raw data into nice graphs you actually look at.

They're almost always used together — Prometheus collects, Grafana displays.

---

## Helm — Package Manager for Kubernetes

Just like `brew install` installs software on your Mac, `helm install` installs entire pre-built applications into your Kubernetes cluster.

Prometheus and Grafana have official "Helm charts" — pre-packaged configurations — so you don't write everything from scratch.

```bash
# Install Helm
brew install helm
```

---

## Setup Steps

### 1. Add the Prometheus community Helm repository
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```
This tells Helm where to find the Prometheus/Grafana package.

### 2. Create a dedicated namespace
```bash
kubectl create namespace monitoring
```
Keeps monitoring tools separate from your app — same namespace concept from Kubernetes Day 3.

### 3. Install the full stack
```bash
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring
```

This single command installs:
- **Prometheus** — the metrics database
- **Grafana** — the dashboard tool
- **Alertmanager** — handles alerts when something breaks
- **Prometheus Operator** — manages Prometheus configuration
- **kube-state-metrics** — exposes cluster state as metrics
- **node-exporter** — collects metrics from the node itself

### 4. Verify everything is running
```bash
kubectl get pods -n monitoring
```
Wait 1-2 minutes for all pods to show `Running`.

---

## Accessing Grafana

### Get the admin password
```bash
kubectl get secret --namespace monitoring -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode ; echo
```

### Port-forward to access in browser
```bash
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=monitoring" -oname)
kubectl --namespace monitoring port-forward $POD_NAME 3000
```

**What port-forward does:** Takes a port from inside the cluster (3000, where Grafana runs) and makes it accessible on your Mac at `localhost:3000`. Keep the terminal open while using it.

Open browser: **http://localhost:3000**
Login: `admin` + the password from above

---

## What Came Pre-Built

After installing, Grafana already has dozens of dashboards ready to use — no building required:

- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Namespace (Pods)
- Kubernetes / Compute Resources / Pod
- Kubernetes / Networking / Cluster
- Kubernetes / API server
- CoreDNS
- etcd
- Alertmanager / Overview

This is the power of Helm charts — production-grade dashboards included automatically.

---

## Cleanup

```bash
# Ctrl+C in the port-forward terminal first
helm uninstall monitoring -n monitoring
kubectl delete namespace monitoring
minikube stop
```

`helm uninstall` removes everything the Helm chart installed in one command — much cleaner than deleting dozens of individual YAML resources manually.

---

## Commands Reference

```bash
brew install helm                                    # install Helm
helm repo add NAME URL                                # add a chart repository
helm repo update                                       # refresh repo data
helm install RELEASE_NAME CHART -n NAMESPACE          # install a chart
helm uninstall RELEASE_NAME -n NAMESPACE              # remove a chart
kubectl get pods -n monitoring                         # check status
kubectl port-forward POD_NAME LOCAL_PORT:POD_PORT     # access from browser
```

---

## What's Next

- Get live data showing in dashboards
- Learn PromQL basics — the query language for Prometheus
- Connect monitoring back to your own Flask app
- Set up Alerting — get notified automatically when something breaks
