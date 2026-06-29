# Kubernetes — Ingress
### Smart Traffic Routing into Your Cluster

---

## What is Ingress

NodePort exposes your app on an ugly high port like 30080. Nobody visits myapp.com:30080 in production.

Ingress is a smart traffic router that sits in front of all your services. Receives all traffic on port 80/443 and routes it to the right service based on URL path or domain.

```
Without Ingress:
myapp.com:30080 → my-app service

With Ingress:
myapp.com/        → my-app service
myapp.com/api     → api service
myapp.com/admin   → admin service
```

One clean entry point. Multiple services. Real URLs.

---

## Two Parts to Ingress

**1. Ingress Controller** — the actual software doing the routing. nginx running inside your cluster. Install once.

**2. Ingress Resource** — YAML file defining routing rules. "Send /api traffic to api service."

You need both. Ingress resource without Controller does nothing.

---

## Setup

Enable Ingress Controller in Minikube:
```bash
minikube addons enable ingress
```

Verify it's running:
```bash
kubectl get pods -n ingress-nginx
# ingress-nginx-controller-xxxxx   1/1   Running
```

---

## ingress.yaml

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

**Each part:**
- `annotations` — extra instructions for the Controller. rewrite-target strips path and sends clean `/` to backend.
- `host: myapp.local` — only route traffic with this domain name
- `path: /` — match any request starting with /
- `pathType: Prefix` — / matches /, /anything, /anything/else
- `backend: service` — send to this service on this port

---

## Traffic Flow

```
Browser/curl → myapp.local
    → Ingress Controller (nginx)
        → reads rules in ingress.yaml
            → forwards to my-app service port 80
                → one of the 3 pods
                    → nginx responds
```

---

## Testing on Minikube (Mac + Docker driver)

```bash
# Add to /etc/hosts
echo "192.168.49.2 myapp.local" | sudo tee -a /etc/hosts

# Start tunnel (keep terminal open)
minikube tunnel

# Test with host header (Mac Docker driver quirk)
curl -H "Host: myapp.local" http://127.0.0.1
# Returns nginx welcome page ✓
```

Note: On real cloud (EKS), Ingress gets a real external IP and works directly in browser.

---

## Commands

```bash
kubectl apply -f ingress.yaml       # create ingress
kubectl get ingress                 # list ingress resources
kubectl describe ingress NAME       # see routing rules and events
kubectl delete -f ingress.yaml      # delete ingress
minikube addons enable ingress      # enable ingress controller
```

---

## Concepts to Know

**Persistent Volumes** — external storage that survives pod restarts. Pods are temporary — data inside dies when pod dies. PV attaches external storage (like EBS) so data persists.

**Resource Limits** — cap how much CPU/memory a pod can use. Prevents one bad pod from starving the whole cluster.
```yaml
resources:
  limits:
    cpu: "0.5"
    memory: "128Mi"
```