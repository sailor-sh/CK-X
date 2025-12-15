#!/bin/bash
# Q18.02 - Service type is ClusterIP
# Points: 2

NS="services-clusterip"
TYPE=$(kubectl get svc web-svc -n "$NS" -o jsonpath='{.spec.type}' 2>/dev/null)
if [ "$TYPE" = "ClusterIP" ]; then
  echo "✓ Service type is ClusterIP"
  exit 0
else
  echo "✗ Service type is '$TYPE', expected 'ClusterIP'"
  exit 1
fi

