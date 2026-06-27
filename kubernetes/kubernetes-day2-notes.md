# Kubernetes — Day 2
### YAML Files + ConfigMap + Self-Healing Watch Mode

---

## The Big Shift from Day 1

Day 1: typed commands directly
```bash
kubectl create deployment my-app --image=nginx
```

Day 2: write YAML files, apply them
```bash
kubectl apply -f deployment.yaml
```

Why YAML files:
- Stored in GitHub — whole team can see and review
- Reusable — apply anytime to get exact same result
- Updatable — change the file, reapply, Kubernetes updates automatically
- This is how real DevOps engineers work

---

## The Three Files We Created

### deployment.yaml
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
```

### service.yaml
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

### configmap.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-config
data:
  ENVIRONMENT: "development"
  APP_NAME: "my-flask-app"
```

---

## Key Concepts

### Labels — how everything connects
Labels are name tags on pods. Other resources find pods by looking for matching labels.

```
Deployment selector: app: my-app → finds pods with this label
Service selector:    app: my-app → sends traffic to pods with this label
Pod label:           app: my-app → this is me
```

Same label = connected. That's the glue of Kubernetes.

### ConfigMap — separate config from code
Stores environment variables outside the container. Change config without rebuilding Docker image.

```bash
# Verify variables are inside the pod
kubectl exec POD_NAME -- env | grep -E "ENVIRONMENT|APP_NAME"
# ENVIRONMENT=development
# APP_NAME=my-flask-app
```

### kubectl apply vs kubectl create
- `kubectl apply -f file.yaml` → creates if new, updates if exists
- `kubectl delete -f file.yaml` → deletes whatever is in the file
- Saw "configured" instead of "created" when reapplying after changes

### Traffic flow
```
Browser → localhost:30080
    → Service (port 80)
        → one of the 3 pods (port 80)
            → nginx responds
```

---

## Self-Healing Watch Mode

Terminal 1:
```bash
kubectl get pods -w
```

Terminal 2:
```bash
kubectl delete pod POD_NAME
```

What Terminal 1 showed:
```
my-app-xxx   Running          ← alive
my-app-xxx   Terminating      ← deleted
my-app-yyy   Pending          ← replacement starting
my-app-yyy   ContainerCreating
my-app-yyy   Running          ← healed in 4 seconds ✓
```

---

## All Commands

```bash
kubectl apply -f filename.yaml        # create or update
kubectl delete -f filename.yaml       # delete
kubectl get pods -w                   # watch live updates
kubectl exec POD_NAME -- command      # run command inside pod
kubectl get all                       # see everything
```

---

## Cleanup — run every session end

```bash
kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
kubectl delete -f configmap.yaml
minikube stop
```

---

## Mental Map

```
ConfigMap → env vars injected into →
Deployment → creates pods with label app: my-app
Service → finds pods via label app: my-app → forwards traffic
Browser → Service → Pod → nginx
```