# Kubernetes — Secrets
### Storing Sensitive Config Separately from Code

---

## What is a Secret

Like a ConfigMap but for sensitive data — passwords, API keys, database credentials, tokens.

ConfigMap → non-sensitive config → fine to push to GitHub
Secret → sensitive config → NEVER push to GitHub

Same idea — keeps config outside the container. But encrypted and restricted.

---

## Secret vs ConfigMap

| | ConfigMap | Secret |
|---|---|---|
| What | Non-sensitive config | Sensitive config |
| Example | ENVIRONMENT, APP_NAME | DB_PASSWORD, API_KEY |
| GitHub | Fine to push | Never push |
| Values | Plain text | Base64 encoded |

---

## secret.yaml

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

**`type: Opaque`** — most common Secret type. Means arbitrary data. Use this for general passwords and keys.

**`data:`** — values must be base64 encoded. Kubernetes decodes them automatically before injecting into pods.

---

## Base64 Encoding

```bash
# Encode a value
echo -n "mypassword123" | base64
# bXlwYXNzd29yZDEyMw==

# -n is important — no newline at end
# Without -n the newline gets encoded too → wrong output
```

Base64 is NOT encryption. It's just encoding. Security comes from Kubernetes restricting who can access Secrets, not from base64.

---

## Inject Secret into Pod

In deployment.yaml, add secretRef below configMapRef:

```yaml
        envFrom:
        - configMapRef:
            name: my-app-config
        - secretRef:
            name: my-app-secret
```

Kubernetes decodes base64 and injects real values as environment variables.

---

## Verify Secrets Inside Pod

```bash
kubectl exec POD_NAME -- env | grep -E "DB_PASSWORD|API_KEY"
# DB_PASSWORD=mypassword123
# API_KEY=supersecretkey
```

Pod sees real decoded values, not base64.

---

## The Complete Config Picture

```
ConfigMap → ENVIRONMENT=development, APP_NAME=my-flask-app
Secret    → DB_PASSWORD=mypassword123, API_KEY=supersecretkey
Both injected as env vars into every pod
Container just reads env vars — doesn't care where they came from
```

---

## Never Push Secrets to GitHub

Add to .gitignore:
```
secret.yaml
```

In real companies secrets are managed via:
- AWS Secrets Manager
- HashiCorp Vault
- Environment-specific files that are gitignored

---

## Commands

```bash
kubectl apply -f secret.yaml           # create secret
kubectl get secrets                    # list secrets
kubectl describe secret my-app-secret  # see secret details (values hidden)
kubectl delete secret my-app-secret    # delete secret
```