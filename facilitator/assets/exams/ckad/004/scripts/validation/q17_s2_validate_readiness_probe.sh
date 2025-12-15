#!/bin/bash
# Q17.02 - Readiness probe configured (HTTP GET / on 80)
# Points: 4

NS="readiness-probes"
PATH=$(kubectl get pod ready-web -n "$NS" -o jsonpath='{.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null)
PORT=$(kubectl get pod ready-web -n "$NS" -o jsonpath='{.spec.containers[0].readinessProbe.httpGet.port}' 2>/dev/null)
if [ "$PATH" = "/" ] && [ "$PORT" = "80" ]; then
  echo "✓ Readiness probe HTTP GET /:80 configured"
  exit 0
else
  echo "✗ Readiness probe not configured as expected (path=$PATH, port=$PORT)"
  exit 1
fi

