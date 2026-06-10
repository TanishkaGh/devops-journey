# Kubernetes — Day 1
### Core Concepts + First Deployment on Minikube

---

## Why Kubernetes Exists

Docker runs one container on one server. That's fine for small apps. But real production apps need:

- **Scaling** — run 10 containers simultaneously when traffic spikes
- **Self-healing** — automatically restart containers that crash
- **Zero downtime updates** — deploy new versions without users noticing
- **Multi-server management** — spread containers across many servers automatically

Kubernetes solves all four.

---

## Core Concepts

**Cluster** — the entire Kubernetes system. A group of servers working together as one unit.

**Node** — a single server inside the cluster. In Minikube = your Mac. In production = EC2 instances.
- Control plane node = the manager (makes decisions)
- Worker node = the worker (runs your containers)

**Pod** — the smallest unit in Kubernetes. A wrapper around one or more containers. You never run containers directly in Kubernetes — you run pods.
- One pod = one instance of your app
- Each pod gets its own IP address inside the cluster
- Pods are temporary and disposable

**Deployment** — tells Kubernetes how many pods to run at all times. If a pod crashes, the Deployment automatically creates a replacement. You manage Deployments, not individual pods.

**Service** — gives pods a stable fixed address. Pods get created/destroyed constantly with changing IPs. A Service sits in front and provides one consistent address. Acts as a load balancer.

- **ClusterIP** — only inside the cluster
- **NodePort** — accessible from outside via a port on the node
- **LoadBalancer** — cloud load balancer (production on AWS)

**kubectl** — command line tool to control Kubernetes. Like AWS CLI but for K8s.

---

## Mental Map

```
Cluster
    └── Node (your Mac / EC2 in production)
          ├── Pod (your app container)
          ├── Pod (your app container)
          └── Pod (your app container)
                    ▲
              Deployment (keeps pods running, handles scaling)
              Service (stable address → forwards to pods)
```

---

## Setup

**Minikube** — runs a single-node Kubernetes cluster locally on your Mac. Free, no AWS needed.

```bash
# Start Docker Desktop first (required)
open /Applications/Docker.app

# Start Minikube
minikube start

# Verify cluster is running
kubectl get nodes
# Should show: minikube   Ready
```

---

## Commands We Used Today

```bash
# Create a deployment
kubectl create deployment my-app --image=nginx

# Check pods
kubectl get pods
kubectl get pods -o wide        # shows IP, node info

# Scale to 3 replicas
kubectl scale deployment my-app --replicas=3

# Delete a pod (Kubernetes recreates it automatically)
kubectl delete pod POD_NAME

# Expose deployment as a service
kubectl expose deployment my-app --port=80 --type=NodePort

# Check services
kubectl get services

# Get URL to access app in browser
minikube service my-app --url

# See everything at once
kubectl get all

# Delete deployment (also deletes all its pods)
kubectl delete deployment my-app

# Delete service
kubectl delete service my-app

# Stop Minikube
minikube stop
```

---

## Key Concepts Demonstrated

### Self-healing
```
kubectl scale deployment my-app --replicas=3
# 3 pods running

kubectl delete pod POD_NAME
# Pod deleted → Kubernetes immediately creates replacement
# Count never drops below 3
```

**Why:** The Deployment constantly checks "how many pods are running?" vs "how many should be running?" Any mismatch → it fixes it automatically.

### The right way to stop pods
```bash
# Wrong — Kubernetes just recreates the pod
kubectl delete pod POD_NAME

# Right — scale to 0, no pods recreated
kubectl scale deployment my-app --replicas=0

# Right — delete everything
kubectl delete deployment my-app
```

### What `kubectl get all` shows
```
NAME                         READY   STATUS    
pod/my-app-xxx-yyy           1/1     Running   ← actual running containers

NAME                 TYPE        CLUSTER-IP    PORT(S)        
service/my-app       NodePort    10.x.x.x      80:32584/TCP   ← stable address

NAME                     READY   UP-TO-DATE   AVAILABLE   
deployment.apps/my-app   3/3     3            3           ← desired vs actual

NAME                               DESIRED   CURRENT   READY   
replicaset.apps/my-app-xxx         3         3         3       ← manages the pods
```

**ReplicaSet** — created automatically by the Deployment. It's what actually manages the pod count. You rarely interact with it directly.

---

## What's Next

- Write YAML files instead of using kubectl commands (the real way)
- Deploy your actual Flask app
- Self-healing demo with `kubectl get pods -w`
- ConfigMaps and Secrets
- Eventually — EKS on AWS

---

## Important Notes

- Always start Docker Desktop before `minikube start`
- Minikube stops when you shut down your Mac — always run `minikube start` at the beginning of each session
- `kubectl get pods -w` = watch mode, shows live updates
- ECR images won't work directly in Minikube without AWS credentials configured — use public images for local learning