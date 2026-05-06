# Day 6 — Docker

## What I did
- Installed Docker on EC2
- Pulled and ran official Nginx container
- Wrote a Dockerfile for a Python Flask app
- Built my own Docker image (myapp:v1)
- Ran it as a container and tested with curl
- Got inside a running container with docker exec

## Key concepts
- Image = blueprint (read only, reusable)
- Container = running instance of an image
- Dockerfile = instructions to build an image
- RUN = runs at build time (install things)
- CMD = runs at container start (start your app)
- Port mapping: -p HOST_PORT:CONTAINER_PORT

## Commands
docker pull IMAGE
docker run -d -p 80:80 nginx
docker ps / docker ps -a
docker stop / docker rm
docker build -t name:tag .
docker exec -it ID bash
docker logs ID
docker images

## What went wrong
- Port 80 already in use — nginx from Day 2 still running
- Fixed with: sudo systemctl stop nginx