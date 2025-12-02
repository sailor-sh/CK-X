#!/bin/bash
set -euo pipefail
NAMESPACE="platform"
kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 && echo "Success" || { echo "Namespace missing"; exit 1; }

