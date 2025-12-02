#!/bin/bash
set -euo pipefail
kubectl get configmap app-config -n default >/dev/null 2>&1 && echo "Success" || { echo "Missing CM"; exit 1; }

