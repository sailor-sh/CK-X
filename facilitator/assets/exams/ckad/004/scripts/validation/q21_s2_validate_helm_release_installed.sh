#!/bin/bash
# Q21.02 - Helm release my-web installed (heuristic)
# Points: 4

NS="helm-ns"
# Heuristic: look for resources labeled with Helm release instance
COUNT=$(kubectl get all -n "$NS" -l app.kubernetes.io/instance=my-web --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ -n "$COUNT" ] && [ "$COUNT" -ge 1 ] 2>/dev/null; then
  echo "✓ Resources labeled with release my-web present"
  exit 0
else
  echo "✗ No resources found labeled with app.kubernetes.io/instance=my-web"
  exit 1
fi

