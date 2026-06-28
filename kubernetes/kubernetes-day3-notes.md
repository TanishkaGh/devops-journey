# Kubernetes — Day 3
### Rolling Updates + Rollback + Namespaces

---

## Rolling Update — Zero Downtime Deployment

### The Problem
You have 3 pods running v1. You want to deploy v2.
Without Kubernetes: stop all 3 → start 3 new → 30 seconds downtime. Users see errors.

### The Solution — Rolling Update
Kubernetes replaces pods one by one:
- Start 1 new pod (v2) → wait for it to be ready
- Stop 1 old pod (v1)
- Start 1 new pod (v2) → wait for it to be ready
- Stop 1 old pod (v1)
- Repeat until all pods are new version

At no point are all pods down. Users never see an error.

### How to trigger
Change the image in `deployment.yaml`:
```yaml
containers:
- name: my-app
  image: nginx:1.25    # changed from nginx
```

Then apply:
```bash
kubectl apply -f deployment.yaml
```

Watch it happen:
```bash
kubectl get pods -w
```

What you see:
```
new pod (v2)  ContainerCreating → Running    ← new pod ready first
old pod (v1)  Terminating                    ← only then old pod removed
new pod (v2)  ContainerCreating → Running    ← next replacement
old pod (v1)  Terminating
...
```

Old pod hash: `6bdb69874-xxxxx`
New pod hash: `7fd6db7b94-xxxxx`
Different hash = different version.

---

## Rollback — Go Back to Previous Version

### When you need it
Bad deployment goes out. App is broken. You need to go back immediately.

### Commands
```bash
# Undo last deployment (go back one version)
kubectl rollout undo deployment/my-app

# Go back to specific revision
kubectl rollout undo deployment/my-app --to-revision=1

# Check rollout status
kubectl rollout status deployment/my-app

# See revision history
kubectl rollout history deployment/my-app
```

Rollout history shows:
```
REVISION  CHANGE-CAUSE
1         <none>    ← nginx (original)
2         <none>    ← nginx:1.25 (update)
```

Rollback does the same rolling process in reverse — one pod at a time, zero downtime.

### Verify what's running
```bash
kubectl describe deployment my-app | grep Image
```

---

## Namespaces — Folders Inside Your Cluster

### What they are
Namespaces are like folders inside your cluster. They keep resources organized and isolated from each other.

Default namespaces:
- `default` — where your stuff goes if you don't specify
- `kube-system` — Kubernetes internals, don't touch
- `kube-public` — public cluster info
- `kube-node-lease` — internal heartbeat system

### Real world use
```
namespace: dev        ← developers test here
namespace: prod       ← real users, real traffic
namespace: monitoring ← Prometheus, Grafana
```

Teams can't accidentally affect each other's resources.

### Commands
```bash
# List all namespaces
kubectl get namespaces

# Create a namespace
kubectl create namespace dev

# Deploy into a namespace
kubectl apply -f deployment.yaml -n dev

# See pods in a namespace
kubectl get pods -n dev

# Delete namespace (removes everything inside it)
kubectl delete namespace dev
```

### Critical rule — resources don't cross namespaces
ConfigMap in `default` namespace is invisible to pods in `dev` namespace. If your deployment needs a ConfigMap, you must apply the ConfigMap to the same namespace.

```bash
# Wrong — ConfigMap in default, deployment in dev
kubectl apply -f deployment.yaml -n dev
# Pods get CreateContainerConfigError

# Right — both in same namespace
kubectl apply -f configmap.yaml -n dev
kubectl apply -f deployment.yaml -n dev
```

---

## All Commands Reference

```bash
# Rolling update
kubectl apply -f deployment.yaml       # triggers update if image changed

# Rollback
kubectl rollout undo deployment/NAME
kubectl rollout undo deployment/NAME --to-revision=N
kubectl rollout status deployment/NAME
kubectl rollout history deployment/NAME

# Namespaces
kubectl get namespaces
kubectl create namespace NAME
kubectl apply -f file.yaml -n NAMESPACE
kubectl get pods -n NAMESPACE
kubectl delete namespace NAME

# Check what image is running
kubectl describe deployment NAME | grep Image
```

---

## Cleanup Every Session
```bash
kubectl delete -f deployment.yaml -n dev
kubectl delete -f configmap.yaml -n dev
kubectl delete namespace dev
kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
kubectl delete -f configmap.yaml
minikube stop
```

---

## Mental Map

```
Rolling Update:
new pod ready → old pod removed → new pod ready → old pod removed
Always 3 pods running. Zero downtime.

Rollback:
kubectl rollout undo → reverses the process → back to previous version

Namespaces:
default namespace    dev namespace
[pod][pod][pod]      [pod][pod][pod]
completely isolated — ConfigMaps don't cross namespaces
```