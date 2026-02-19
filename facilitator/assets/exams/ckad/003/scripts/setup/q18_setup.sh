#!/usr/bin/env bash
set -euo pipefail
kubectl get ns svc-fix-endpoints >/dev/null 2>&1 || kubectl create ns svc-fix-endpoints

# Create deployment
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: manager-api-deployment
  namespace: svc-fix-endpoints
spec:
  replicas: 2
  selector:
    matchLabels: {app: manager-api}
  template:
    metadata:
      labels: {app: manager-api}
    spec:
      containers:
      - name: api
        image: nginx:1.21.6-alpine
        ports:
        - containerPort: 4444
EOF

# Intentionally broken service: wrong selector and/or ports
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: manager-api-svc
  namespace: svc-fix-endpoints
spec:
  selector:
    app: wrong-selector
  ports:
  - port: 4444
    targetPort: 1234
    protocol: TCP
EOF

mkdir -p /opt/course/exam3/q18
