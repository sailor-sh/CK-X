#!/usr/bin/env bash
set -euo pipefail
kubectl get ns secrets-cm >/dev/null 2>&1 || kubectl create ns secrets-cm

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secret-handler
  namespace: secrets-cm
spec:
  containers:
  - name: app
    image: nginx:1.21.6-alpine
EOF

mkdir -p /opt/course/exam3/q14
