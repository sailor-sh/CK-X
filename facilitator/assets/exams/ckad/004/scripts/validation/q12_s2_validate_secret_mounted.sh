#!/bin/bash
# Q12.02 - Secret mounted at /etc/app-secret
# Points: 3

NS="secrets-volume"
MP=$(kubectl get pod sec-pod -n "$NS" -o jsonpath='{range .spec.volumes[?(@.secret.secretName=="app-secret")]}{.name}{"\n"}{end}' 2>/dev/null)
MOUNT=$(kubectl get pod sec-pod -n "$NS" -o jsonpath='{range .spec.containers[0].volumeMounts[?(@.mountPath=="/etc/app-secret")]}{.name}{end}' 2>/dev/null)
if [ -n "$MP" ] && [ -n "$MOUNT" ]; then
  echo "✓ Secret app-secret mounted at /etc/app-secret"
  exit 0
else
  echo "✗ Secret app-secret not mounted at /etc/app-secret"
  exit 1
fi

