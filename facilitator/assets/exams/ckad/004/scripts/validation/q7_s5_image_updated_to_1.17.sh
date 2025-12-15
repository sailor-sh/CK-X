#!/bin/bash
# Q7.5 - Image updated to 1.17
# Points: 2

kubectl get deployment web-deploy -n rolling-updates -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | grep -q '1.17' && {
  echo "✓ Image updated to 1.17"
  exit 0
} || {
  echo "✗ Image not updated"
  exit 1
}
