#!/usr/bin/env bash
set -euo pipefail
NS=ckad-p1
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"
mkdir -p /opt/course/exam3/p1
kubectl -n "$NS" delete deploy project-23-api --ignore-not-found=true
cat >/opt/course/exam3/p1/project-23-api.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: project-23-api
  namespace: ckad-p1
spec:
  replicas: 1
  selector:
    matchLabels: { app: project-23-api }
  template:
    metadata:
      labels: { app: project-23-api }
    spec:
      containers:
      - name: api
        image: nginx:1.17.3-alpine
        ports:
        - containerPort: 80
EOF
kubectl apply -f /opt/course/exam3/p1/project-23-api.yaml
echo "Seeded deployment and original YAML for ${NS}."
