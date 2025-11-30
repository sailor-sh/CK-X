#!/usr/bin/env bash
set -euo pipefail
NS_SRC=ckad-q07-source
NS_TGT=ckad-q07-target
kubectl get ns "$NS_SRC" >/dev/null 2>&1 || kubectl create ns "$NS_SRC"
kubectl get ns "$NS_TGT" >/dev/null 2>&1 || kubectl create ns "$NS_TGT"

# Seed source pod to be moved
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: webserver-sat-003
  namespace: ckad-q07-source
  labels:
    id: webserver-sat-003
  annotations:
    description: "this is the server for the E-Commerce System my-happy-shop"
spec:
  containers:
  - name: webserver-sat
    image: nginx:1.16.1-alpine
EOF
echo "Seeded webserver-sat-003 in ${NS_SRC}."
