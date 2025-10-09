#!/bin/bash

set -euo pipefail
IFS=$'
	'

# Ensure a clean namespace: platform
if kubectl get namespace 'platform' >/dev/null 2>&1; then
  kubectl delete namespace 'platform' --wait=true || true
fi
kubectl create namespace 'platform' >/dev/null 2>&1 || true

kubectl delete deployment 'api-gateway' -n 'platform' --ignore-not-found=true || true
kubectl delete service 'api-gateway-svc' -n 'platform' --ignore-not-found=true || true

echo "Setup complete: In the namespace 'platform', create a Deployment named 'api-gateway' with exactly 2 replicas."
exit 0
