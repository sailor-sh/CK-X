#!/bin/bash

set -euo pipefail
IFS=$'
	'

# Ensure a clean namespace: default
if kubectl get namespace 'default' >/dev/null 2>&1; then
  kubectl delete namespace 'default' --wait=true || true
fi
kubectl create namespace 'default' >/dev/null 2>&1 || true

kubectl delete configmap 'app-config' -n 'default' --ignore-not-found=true || true

echo "Setup complete: Create a ConfigMap named 'app-config' in the 'default' namespace with the following data: key1: value1, key2: value2."
exit 0
