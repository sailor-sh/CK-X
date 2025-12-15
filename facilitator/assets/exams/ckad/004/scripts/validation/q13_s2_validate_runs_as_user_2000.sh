#!/bin/bash
# Q13.02 - Runs as user 2000
# Points: 3

NS="security-contexts"
USER=$(kubectl get pod secure-pod -n "$NS" -o jsonpath='{.spec.securityContext.runAsUser}' 2>/dev/null)
if [ -z "$USER" ]; then
  USER=$(kubectl get pod secure-pod -n "$NS" -o jsonpath='{.spec.containers[0].securityContext.runAsUser}' 2>/dev/null)
fi
if [ "$USER" = "2000" ]; then
  echo "✓ Pod/container runs as user 2000"
  exit 0
else
  echo "✗ runAsUser is '$USER', expected '2000'"
  exit 1
fi

