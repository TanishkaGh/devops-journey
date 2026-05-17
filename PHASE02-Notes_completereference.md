# Phase 2 — Docker & CI/CD Complete Reference Notes
### Days 6-8 · Every concept, every command

---

## The Big Picture — What Phase 2 Built

```
Your Code (Mac)
      │
      │ git push
      ▼
GitHub Actions (automated pipeline)
      │
      ├── Run tests (pytest)
      ├── Build Docker image
      ├── Push to ECR
      └── Deploy to EC2
            │
            ▼
      App running in Docker container
      accessible on port 5000
```

---

## DOCKER — Days 6 & 7

### Core Concepts

**Image** = blueprint. Read-only. Built from a Dockerfile.
**Container** = running instance of an image. Isolated environment.
**Dockerfile** = instructions to build an image.
**Docker Hub** = public registry of pre-built images.
**ECR** = AWS's private Docker image registry.

```
Dockerfile → docker build → Image → docker run → Container
```

### Dockerfile Instructions

```dockerfile
FROM python:3.11-slim      # base image to start from
WORKDIR /app               # set working directory inside container
COPY requirements.txt .    # copy file from machine to container
RUN pip install -r requirements.txt  # runs at BUILD time
COPY . .                   # copy everything else
EXPOSE 5000                # document which port app uses
CMD ["python", "app.py"]   # runs at CONTAINER START time
```

**RUN vs CMD:**
- `RUN` = build time (install software)
- `CMD` = start time (run your app)

**Why copy requirements.txt before app code?**
Docker caches layers. If requirements don't change, Docker skips pip install on next build — faster builds.

### Essential Docker Commands

```bash
# Images
docker pull IMAGE                    # download from Docker Hub
docker build -t name:tag .           # build from Dockerfile
docker images                        # list all images
docker rmi IMAGE_ID                  # delete image

# Containers
docker run -d -p HOST:CONT IMAGE     # run in background
docker run -it IMAGE bash            # run interactively
docker ps                            # list running containers
docker ps -a                         # list all containers
docker stop CONTAINER_ID             # stop container
docker start CONTAINER_ID            # start stopped container
docker rm CONTAINER_ID               # delete container
docker rm -f CONTAINER_ID            # force stop and delete
docker logs CONTAINER_ID             # view output
docker exec -it CONTAINER_ID bash    # get shell inside container

# Cleanup
docker system prune                  # remove all unused resources
```

### Docker Compose

Run multiple containers with one command.

```yaml
services:
  web:
    build: .
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=development
  nginx:
    image: nginx
    ports:
      - "80:80"
    depends_on:
      - web
```

```bash
docker-compose up -d      # start all services
docker-compose down       # stop and remove all
docker-compose ps         # list services
docker-compose logs       # view all logs
```

**Key YAML rules:**
- Spaces only, never tabs
- Indentation must be exact

### ECR Workflow

```bash
# Create repository (from Mac)
aws ecr create-repository --repository-name myapp --region ap-south-1

# Authenticate Docker to ECR (from EC2)
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com

# Tag image
docker tag myapp:v1 ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/myapp:v1

# Push
docker push ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/myapp:v1

# Verify
aws ecr list-images --repository-name myapp --region ap-south-1
```

### IAM Role for EC2 → ECR Access

Never store AWS credentials on a server. Use IAM roles instead.

```
1. Create role (trust EC2 service)
2. Attach AmazonEC2ContainerRegistryFullAccess policy
3. Create instance profile
4. Add role to profile
5. Associate profile with EC2 instance
```

The EC2 gets permissions automatically — no credentials stored on the server.

---

## CI/CD PIPELINE — Day 8

### What is CI/CD?

**CI (Continuous Integration)** = automatically test every code push
**CD (Continuous Deployment)** = automatically deploy after tests pass

Without CI/CD: push code → manually SSH → manually pull → manually restart → 15 minutes every time.
With CI/CD: push code → everything happens automatically → app live in 2 minutes.

### GitHub Actions Key Concepts

| Concept | What it is |
|---------|-----------|
| Workflow | The entire automated process, defined in YAML |
| Trigger | What starts it (push to main) |
| Job | Group of steps on one runner |
| Step | One task — shell command or pre-built action |
| Runner | Fresh Ubuntu computer GitHub provides |
| Action | Pre-built reusable step (actions/checkout etc) |
| Secret | Encrypted variable stored in GitHub |

### Workflow File Structure

Location: `.github/workflows/deploy.yml`

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]        # trigger on push to main

env:                           # workflow-level variables
  AWS_REGION: ap-south-1

jobs:
  job-name:
    runs-on: ubuntu-latest
    needs: other-job           # run only after other-job passes
    steps:
      - name: Step label
        uses: owner/action@v3  # pre-built action
        with:
          param: value

      - name: Step label
        run: shell command here # direct shell command
```

### The Three Jobs We Built

**Job 1: test**
```yaml
- Checkout code (actions/checkout)
- Install Python 3.11 (actions/setup-python)
- pip install -r docker/requirements.txt
- cd docker && pytest test_app.py -v
```

**Job 2: build-and-push** (runs only if test passes)
```yaml
- Checkout code
- Configure AWS credentials (aws-actions/configure-aws-credentials)
- Login to ECR
- docker build -t ECR_URI/myapp:${{ github.sha }} ./docker
- docker push ECR_URI/myapp:${{ github.sha }}
```

**Job 3: deploy** (runs only if build-and-push passes)
```yaml
- SSH into EC2 (appleboy/ssh-action)
- Login to ECR from EC2
- docker pull new image
- docker stop myapp || true
- docker rm myapp || true
- docker run -d --name myapp -p 5000:5000 new-image
```

### Important Syntax

```yaml
${{ secrets.SECRET_NAME }}    # reference a GitHub Secret
${{ env.VAR_NAME }}           # reference env variable
${{ github.sha }}             # unique git commit hash
needs: job-name               # job dependency
```

### GitHub Secrets Required

| Secret | What it contains |
|--------|-----------------|
| AWS_ACCESS_KEY_ID | AWS access key |
| AWS_SECRET_ACCESS_KEY | AWS secret key |
| EC2_HOST | EC2 public IP address |
| EC2_USER | ec2-user |
| EC2_SSH_KEY | Full contents of devops-key.pem |

### Tests We Wrote

```python
# test_app.py
from app import add, app

def test_add():
    assert add(2, 3) == 5

def test_health():
    client = app.test_client()
    response = client.get('/health')
    assert response.status_code == 200
```

`assert` = check this is true. If false → test fails → pipeline stops → nothing deploys.

---

## Common Errors and Fixes

| Error | Fix |
|-------|-----|
| `port already in use` | `sudo systemctl stop nginx` |
| `compose build requires buildx` | Install buildx manually |
| `Unable to locate credentials` | Run AWS CLI from Mac, not EC2 |
| `version is obsolete` warning | Remove `version: '3'` from compose file |
| `workflow scope` error on git push | Update token to include workflow scope |
| `missing server host` | Re-add EC2_HOST secret correctly |
| `ssh: no key found` | Paste entire .pem including BEGIN/END lines |

---

## Mental Map — Phase 2 Complete

```
Docker:
  Dockerfile → Image → Container
  One image → many containers
  docker build / docker run / docker ps / docker logs

ECR:
  Private AWS image registry
  authenticate → tag → push → pull from any AWS server

CI/CD Pipeline:
  git push → tests → build image → push ECR → deploy EC2
  Every step automatic
  Secrets stored encrypted in GitHub
  Jobs run in order using needs:
  Commit hash tags every image uniquely
```

---

Phase 2 complete. Everything is automated. Next: Terraform — infrastructure as code.
