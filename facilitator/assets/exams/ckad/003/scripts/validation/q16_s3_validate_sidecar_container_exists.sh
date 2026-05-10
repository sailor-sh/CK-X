#!/usr/bin/env bash
set -euo pipefail
# Validates that the 'logger-con' sidecar container exists in the pod
kubectl -n sidecar-logging get deploy cleaner -o jsonpath='{.spec.template.spec.containers[*].name}' | grep -q "logger-con"