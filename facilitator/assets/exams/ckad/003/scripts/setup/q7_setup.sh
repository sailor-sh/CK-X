#!/usr/bin/env bash
set -euo pipefail
kubectl get ns pod-move-source >/dev/null 2>&1 || kubectl create ns pod-move-source
kubectl get ns pod-move-target >/dev/null 2>&1 || kubectl create ns pod-move-target

# Seed multiple pods in source; only one has the exact annotation containing 'my-happy-shop'
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: webserver-sat-001
  namespace: pod-move-source
  labels:
    app: web
  annotations:
    description: "internal test server for staging shop"
spec:
  containers:
  - name: web
    image: nginx:1.16.1-alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: webserver-sat-002
  namespace: pod-move-source
  labels:
    app: web
  annotations:
    description: "legacy e-commerce demo instance"
spec:
  containers:
  - name: web
    image: nginx:1.16.1-alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: webserver-sat-003
  namespace: pod-move-source
  labels:
    app: web
  annotations:
    description: "this is the server for the E-Commerce System my-happy-shop"
spec:
  containers:
  - name: web
    image: nginx:1.16.1-alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: webserver-sat-004
  namespace: pod-move-source
  labels:
    app: web
  annotations:
    description: "canary for storefront service"
spec:
  containers:
  - name: web
    image: nginx:1.16.1-alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: api-sat-001
  namespace: pod-move-source
  labels:
    app: api
  annotations:
    description: "payments API test rig"
spec:
  containers:
  - name: api
    image: nginx:1.16.1-alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: cache-redis
  namespace: pod-move-source
  labels:
    app: cache
  annotations:
    description: "redis cache instance"
spec:
  containers:
  - name: cache
    image: nginx:1.16.1-alpine
EOF

mkdir -p /opt/course/exam3/q07
