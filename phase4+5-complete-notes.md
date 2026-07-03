# Phase 4 & 5 — Kubernetes + Monitoring
### Complete Reference Notes

---

## PHASE 4 — KUBERNETES

### Why Kubernetes Exists

Docker runs one container on one server. Fine for small apps. Real production apps need:
- **Scaling** — run 10 containers when traffic spikes
- **Self-healing** — restart crashed containers automatically
- **Zero downtime updates** — deploy new versions without users noticing
- **Multi-server management** — spread containers across many servers

Kubernetes solves all four.

---

### Core Concepts

**Cluster** — the entire Kubernetes system. A group of servers working together as one unit.

**Node** — a single server inside the cluster. Your Mac in Minikube. EC2 in production.
- Control plane = the brain (makes decisions)
- Worker = the muscle (runs containers)

**Pod** — smallest unit. Wrapper around one container. You never run containers directly in Kubernetes — everything goes through pods. Each pod gets its own IP address. Pods are temporary and disposable.

**Deployment** — tells Kubernetes how many pods to run at all times. Self-heals automatically. You manage Deployments, not individual pods.

**Service** — stable fixed address in front of pods. Pods die and get new IPs constantly — Service gives one consistent address. Acts as load balancer.
- ClusterIP — only inside cluster
- NodePort — accessible from outside via port
- LoadBalancer — cloud load balancer (production)

**kubectl** — command line tool to control Kubernetes.

**Mental map:**
```
Cluster
  └── Node (Mac / EC2)
        ├── Pod (container) ──┐
        ├── Pod (container)   ├── managed by Deployment
        └── Pod (container) ──┘
                  ▲
            Service (stable address)
                  ▲
            Ingress (domain routing)
```

---

### Minikube Setup

```bash
open /Applications/Docker.app    # start Docker Desktop first
minikube start                    # start local cluster
kubectl get nodes                 # verify: minikube Ready
minikube stop                     # stop cluster
```

---

### Day 1 — Imperative Commands

```bash
# Create deployment
kubectl create deployment my-app --image=nginx

# Check pods
kubectl get pods
kubectl get pods -o wide          # with IP and node info
kubectl get all                   # see everything

# Scale
kubectl scale deployment my-app --replicas=3

# Self-healing — delete pod, Kubernetes recreates it
kubectl delete pod POD_NAME

# Expose as service
kubectl expose deployment my-app --port=80 --type=NodePort

# Access in browser
minikube service my-app --url

# Watch pods in real time (two terminals)
kubectl get pods -w               # Terminal 1 — watch mode
kubectl delete pod POD_NAME       # Terminal 2 — delete pod
# See: Terminating → Pending → ContainerCreating → Running

# Cleanup
kubectl delete deployment my-app
kubectl delete service my-app
```

**To actually stop pods:**
```bash
kubectl scale deployment my-app --replicas=0   # scale to zero
kubectl delete deployment my-app               # delete everything
```

---

### Day 2 — YAML Files (Declarative)

Real DevOps way — write YAML files, apply them, store in GitHub.

**deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx
        ports:
        - containerPort: 80
        envFrom:
        - configMapRef:
            name: my-app-config
        - secretRef:
            name: my-app-secret
```

**service.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
```

**configmap.yaml**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-config
data:
  ENVIRONMENT: "development"
  APP_NAME: "my-flask-app"
```

**secret.yaml** (never push real values to GitHub)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secret
type: Opaque
data:
  DB_PASSWORD: <base64-encoded-value>
  API_KEY: <base64-encoded-value>
```

Encode values: `echo -n "mypassword" | base64`

```bash
kubectl apply -f deployment.yaml    # create or update
kubectl apply -f service.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

kubectl delete -f deployment.yaml   # delete
kubectl exec POD -- env | grep DB_PASSWORD  # verify secrets injected
```

**Labels — the glue of Kubernetes:**
```
Pod label:           app: my-app
Deployment selector: app: my-app → I manage these pods
Service selector:    app: my-app → I send traffic to these pods
```

---

### Day 3 — Rolling Updates + Rollback + Namespaces

**Rolling Update — zero downtime:**
Change image in deployment.yaml → kubectl apply → Kubernetes replaces pods one by one. New pod starts first, gets ready, then old pod removed. Users never see downtime.

```bash
kubectl rollout status deployment/my-app      # check status
kubectl rollout history deployment/my-app     # see all versions
kubectl rollout undo deployment/my-app        # go back one version
kubectl rollout undo deployment/my-app --to-revision=1  # go to specific version
kubectl describe deployment my-app | grep Image  # check current image
```

**Namespaces:**
```bash
kubectl get namespaces
kubectl create namespace dev
kubectl apply -f file.yaml -n dev      # deploy into namespace
kubectl get pods -n dev
kubectl delete namespace dev           # removes everything inside
```

Critical rule: Resources don't cross namespaces. ConfigMap in `default` is invisible to pods in `dev`. Always apply ConfigMap and Secret to the same namespace as your deployment.

---

### Day 4 — Secrets + Ingress

**Secrets** — already covered above in Day 2 YAML section.

**Ingress — smart traffic router:**

Two parts required:
1. Ingress Controller — nginx running inside cluster (install once)
2. Ingress Resource — YAML file with routing rules

```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx    # verify controller running
```

**ingress.yaml**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app
            port:
              number: 80
```

Traffic flow:
```
Browser → myapp.local
  → Ingress Controller
    → reads rules → my-app service port 80
      → one of 3 pods → nginx responds
```

Minikube testing (Mac Docker driver quirk):
```bash
echo "192.168.49.2 myapp.local" | sudo tee -a /etc/hosts
minikube tunnel
curl -H "Host: myapp.local" http://127.0.0.1
```

```bash
kubectl get ingress
kubectl describe ingress my-app-ingress
```

**Concepts to know:**
- Persistent Volumes — external storage that survives pod restarts
- Resource Limits — cap CPU/memory per pod (`limits: cpu: "0.5"`)

---

### Complete kubectl Reference

```bash
# Cluster
kubectl get nodes
kubectl get all
kubectl get pods -w               # watch mode

# Deployments
kubectl create deployment NAME --image=IMAGE
kubectl apply -f file.yaml
kubectl delete -f file.yaml
kubectl scale deployment NAME --replicas=N
kubectl rollout undo deployment/NAME
kubectl rollout history deployment/NAME
kubectl describe deployment NAME

# Pods
kubectl get pods
kubectl get pods -o wide
kubectl delete pod NAME
kubectl exec POD -- command
kubectl logs POD

# Services
kubectl expose deployment NAME --port=80 --type=NodePort
kubectl get services

# Namespaces
kubectl get namespaces
kubectl create namespace NAME
kubectl apply -f file.yaml -n NAMESPACE
kubectl get pods -n NAMESPACE

# Ingress
kubectl apply -f ingress.yaml
kubectl get ingress
kubectl describe ingress NAME
minikube addons enable ingress
```

---

## PHASE 5 — MONITORING

### Why Monitoring

You have Kubernetes self-healing, scaling, deploying. But how do you know if it's healthy right now? CPU too high? Memory running out? Pods crashing? Without monitoring you find out when a customer complains. With monitoring you find out the second it happens.

---

### The Two Tools

**Prometheus** — collects and stores metrics. Constantly scrapes your cluster every few seconds. Stores numbers over time (time-series data). CPU, memory, request count, error rate — all with timestamps.

**Grafana** — turns Prometheus data into visual dashboards. Graphs, charts, alerts.

Analogy: Prometheus = fitness tracker logging everything. Grafana = the app showing you nice graphs.

---

### Helm — Package Manager for Kubernetes

```bash
brew install helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

---

### Setup

```bash
kubectl create namespace monitoring

helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring

kubectl get pods -n monitoring    # wait for all Running
```

What gets installed automatically:
- Prometheus — metrics database
- Grafana — dashboards
- Alertmanager — handles alerts
- Prometheus Operator — manages config
- kube-state-metrics — cluster state metrics
- node-exporter — node-level metrics

---

### Accessing Grafana

```bash
# Get password
kubectl get secret --namespace monitoring -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode ; echo

# Port-forward
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=monitoring" -oname)
kubectl --namespace monitoring port-forward $POD_NAME 3000

# Or via service
kubectl --namespace monitoring port-forward svc/monitoring-grafana 3000:80
```

Open: http://localhost:3000
Login: admin + password above
Note: Use Firefox (Safari/Chrome had issues with local Grafana)

Install with custom password to avoid login issues:
```bash
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --set grafana.adminPassword=admin123
```

---

### PromQL — Prometheus Query Language

Every dashboard panel is powered by a PromQL query.

**Basic queries:**
```promql
kube_pod_info                              # info about every pod
count(kube_pod_info)                       # total pod count
count(kube_pod_info) by (namespace)        # pods per namespace
```

**rate() — how fast is metric changing per second:**
```promql
rate(container_cpu_usage_seconds_total[5m])
# CPU usage rate averaged over last 5 minutes
# Use for: CPU, request rate, error rate
# Returns: small decimal numbers (cores per second)

# Filter to one namespace
rate(container_cpu_usage_seconds_total{namespace="monitoring"}[5m])
```

**increase() — total increase over time window:**
```promql
increase(container_cpu_usage_seconds_total[5m])
# Total CPU consumed in last 5 minutes
# Use for: total requests, total errors
# Returns: bigger numbers than rate()
```

**histogram_quantile() — percentile latency:**
```promql
histogram_quantile(0.99, rate(prometheus_http_request_duration_seconds_bucket[5m]))
# p99 response time of Prometheus
# 0.99 = 99th percentile
# 0.95 = 95th percentile
# 0.50 = median
```

**What is p99?**
Sort 1000 requests by response time. p99 is the time that 99% of requests are faster than. Only the slowest 1% are above it.

p99 = 100ms = excellent
p99 = 500ms = good
p99 > 1000ms = investigate

Smaller p99 = better. Companies obsess over p99, not averages. Averages hide outliers.

---

### Alerting

**Contact point** — where alerts get sent (email, Slack, PagerDuty)
**Alert rule** — the condition that triggers an alert
**Evaluation group** — how often the rule is checked

Setup:
1. Alerting → Contact points → Add contact point → Email → save
2. Alerting → Alert rules → New alert rule
3. Query: `count(kube_pod_info)`
4. Threshold: IS BELOW 5
5. Evaluate every: 1m
6. Assign folder and evaluation group
7. Save rule

---

### Cleanup

```bash
helm uninstall monitoring -n monitoring    # removes everything
kubectl delete namespace monitoring
minikube stop
```

`helm uninstall` removes everything the chart installed in one command.

---

### Helm Commands Reference

```bash
brew install helm
helm repo add NAME URL
helm repo update
helm install RELEASE CHART -n NAMESPACE
helm install RELEASE CHART -n NAMESPACE --set key=value
helm uninstall RELEASE -n NAMESPACE
helm list -n NAMESPACE
```

---

## Mental Map — Everything Connected

```
Phase 1: Control one Linux server (EC2, VPC, networking)
Phase 2: Package app in Docker, automate delivery (CI/CD)
Phase 3: Build infrastructure with code (Terraform)
Phase 4: Run many containers reliably at scale (Kubernetes)
Phase 5: Know if everything is healthy in real time (Monitoring)

Kubernetes cluster
  └── Pods running Docker containers (Phase 2)
        inside VPC + EC2 nodes (Phase 1)
        created by Terraform (Phase 3)
        monitored by Prometheus + Grafana (Phase 5)

One complete DevOps system.
```