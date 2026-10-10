#!/usr/bin/env bash
set -euo pipefail

# Ensure output directory exists for exam artifacts
mkdir -p /opt/course/exam3/p3

kubectl get ns p3-readiness >/dev/null 2>&1 || kubectl create ns p3-readiness

# Wrong readinessProbe port to be fixed by user
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: earth-3cc-web
  namespace: p3-readiness
spec:
  replicas: 4
  selector:
    matchLabels: {app: e3cc}
  template:
    metadata:
      labels: {app: e3cc}
    spec:
      containers:
      - name: web
        image: nginx:1.21.6-alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 8081
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: earth-3cc-web-svc
  namespace: p3-readiness
spec:
  selector:
    app: e3cc
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
EOF
