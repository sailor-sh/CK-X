#!/usr/bin/env bash
set -euo pipefail
kubectl get ns convert-to-deploy >/dev/null 2>&1 || kubectl create ns convert-to-deploy

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: holy-api
  namespace: convert-to-deploy
  labels:
    app: holy-api
spec:
  containers:
  - name: holy
    image: nginx:1.21.6-alpine
    ports:
    - containerPort: 80
EOF

mkdir -p /opt/course/exam3/q09
