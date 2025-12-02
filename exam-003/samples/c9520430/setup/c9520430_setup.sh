#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

if kubectl get namespace 'default' >/dev/null 2>&1; then
  kubectl delete namespace 'default' --wait=true || true
fi
kubectl create namespace 'default' >/dev/null 2>&1 || true

kubectl delete configmap 'app-config' -n 'default' --ignore-not-found=true || true

echo "Setup complete: Create ConfigMap 'app-config' in 'default'."
exit 0

