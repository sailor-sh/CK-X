#!/bin/bash
# Q18.01 - Service web-svc exists
# Points: 2

NS="services-clusterip"
kubectl get svc web-svc -n "$NS" >/dev/null 2>&1 && {
  echo "✓ Service web-svc exists in $NS"
  exit 0
} || {
  echo "✗ Service web-svc not found in $NS"
  exit 1
}

