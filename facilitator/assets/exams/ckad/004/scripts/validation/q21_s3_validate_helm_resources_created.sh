#!/bin/bash
# Q21.03 - Helm created pods/services
# Points: 4

NS="helm-ns"
PODS=$(kubectl get pods -n "$NS" --no-headers | wc -l)
SVCS=$(kubectl get services -n "$NS" --no-headers | wc -l)

if [ $PODS -gt 0 ] && [ $SVCS -gt 0 ]; then
  echo "✓ Helm created pods and services in helm-ns"
  exit 0
else
  echo "✗ Helm did not create expected resources (pods: $PODS, services: $SVCS)"
  exit 1
fi