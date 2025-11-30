#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q18
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"
kubectl -n "$NS" delete deploy manager-api-deployment --ignore-not-found=true
kubectl -n "$NS" delete svc manager-api-svc --ignore-not-found=true
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: manager-api-deployment
  namespace: ckad-q18
spec:
  replicas: 2
  selector:
    matchLabels: { app: manager-api }
  template:
    metadata:
      labels: { app: manager-api }
    spec:
      containers:
      - name: api
        image: nginx:1.17.3-alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: manager-api-svc
  namespace: ckad-q18
spec:
  type: ClusterIP
  selector:
    app: manager-apx # wrong selector intentionally
  ports:
  - name: http
    port: 4444
    targetPort: 80
EOF
echo "Seeded broken service and deployment in ${NS}."
