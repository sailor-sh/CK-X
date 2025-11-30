#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q05
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"
kubectl -n "$NS" delete sa neptune-sa-v2 --ignore-not-found=true
kubectl -n "$NS" create sa neptune-sa-v2
# Create a token secret bound to the SA (if controller populates token)
cat <<'EOF' | kubectl -n ckad-q05 apply -f - || true
apiVersion: v1
kind: Secret
metadata:
  name: neptune-sa-v2-token
  annotations:
    kubernetes.io/service-account.name: "neptune-sa-v2"
type: kubernetes.io/service-account-token
EOF
mkdir -p /opt/course/exam3/q05
echo "Seeded ServiceAccount neptune-sa-v2 and token secret (if supported) in ${NS}."
