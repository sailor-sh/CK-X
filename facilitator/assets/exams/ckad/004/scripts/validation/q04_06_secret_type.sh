#!/bin/bash
# Q04.06 - Secret type is Opaque
# Points: 2

TYPE=$(kubectl get secret app-secret -n q04 -o jsonpath='{.type}' 2>/dev/null)
[[ "$TYPE" == "Opaque" ]] && {
  echo "✓ Secret type is Opaque"
  exit 0
} || {
  echo "✗ Secret type is $TYPE, expected Opaque"
  exit 1
}
