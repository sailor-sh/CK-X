#!/bin/bash
# Q22.01 - CRD definition is correct
# Points: 4

NAME="backups.stable.example.com"
kubectl get crd "$NAME" >/dev/null 2>&1 || { echo "✗ CRD $NAME not found"; exit 1; }

GROUP=$(kubectl get crd "$NAME" -o jsonpath='{.spec.group}' 2>/dev/null)
VERSION=$(kubectl get crd "$NAME" -o jsonpath='{.spec.versions[0].name}' 2>/dev/null)
PLURAL=$(kubectl get crd "$NAME" -o jsonpath='{.spec.names.plural}' 2>/dev/null)
KIND=$(kubectl get crd "$NAME" -o jsonpath='{.spec.names.kind}' 2>/dev/null)

if [ "$GROUP" = "stable.example.com" ] && [ "$VERSION" = "v1" ] && [ "$PLURAL" = "backups" ] && [ "$KIND" = "Backup" ]; then
  echo "✓ CRD definition matches requirements"
  exit 0
else
  echo "✗ CRD fields mismatch (group=$GROUP, version=$VERSION, plural=$PLURAL, kind=$KIND)"
  exit 1
fi

