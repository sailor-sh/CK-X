#!/usr/bin/env bash
set -euo pipefail
kubectl get ns p1-liveness >/dev/null 2>&1 || kubectl create ns p1-liveness

# Ensure output directory exists before writing files
mkdir -p /opt/course/exam3/p1

cat > /opt/course/exam3/p1/project-23-api.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: project-23-api
  namespace: p1-liveness
spec:
  replicas: 1
  selector:
    matchLabels: {app: p23}
  template:
    metadata:
      labels: {app: p23}
    spec:
      containers:
      - name: api
        image: nginx:1.21.6-alpine
        ports:
        - containerPort: 80
EOF

kubectl apply -f /opt/course/exam3/p1/project-23-api.yaml
