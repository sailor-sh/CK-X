#!/bin/bash
# Q21.03 - Pods/Service created by Helm
# Points: 4

NS="helm-ns"
PODS=$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=my-web --no-headers 2>/dev/null | wc -l | tr -d ' ')
SVC=$(kubectl get svc -n "$NS" -l app.kubernetes.io/instance=my-web --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$PODS" -ge 1 ] && [ "$SVC" -ge 1 ]; then
  echo "✓ Helm-created Pods and Service are present"
  exit 0
else
  echo "✗ Missing Helm-created Pods or Service (pods=$PODS, svc=$SVC)"
  exit 1
fi

