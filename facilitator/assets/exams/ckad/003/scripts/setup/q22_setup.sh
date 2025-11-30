#!/usr/bin/env bash
set -euo pipefail
NS=ckad-p3
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"
kubectl -n "$NS" delete deploy earth-3cc-web --ignore-not-found=true
kubectl -n "$NS" delete svc earth-3cc-web-svc --ignore-not-found=true
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: earth-3cc-web
  namespace: ckad-p3
spec:
  replicas: 4
  selector:
    matchLabels: { app: earth-3cc-web }
  template:
    metadata:
      labels: { app: earth-3cc-web }
    spec:
      containers:
      - name: web
        image: nginx:1.17.3-alpine
        ports:
        - containerPort: 80
        readinessProbe:
          tcpSocket:
            port: 81 # wrong port intentionally
          initialDelaySeconds: 5
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: earth-3cc-web-svc
  namespace: ckad-p3
spec:
  type: ClusterIP
  selector:
    app: earth-3cc-web
  ports:
  - name: http
    port: 8080
    targetPort: 80
EOF
mkdir -p /opt/course/exam3/p3
echo "Seeded deployment with wrong readiness probe and service in ${NS}."
