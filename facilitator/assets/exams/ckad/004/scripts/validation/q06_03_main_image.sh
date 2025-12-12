#!/bin/bash
# Q06.03 - Main container is nginx
# Points: 2

IMAGE=$(kubectl get pod multi-container -n q06 -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
[[ "$IMAGE" =~ nginx ]] && {
  echo "✓ Main container is nginx"
  exit 0
} || {
  echo "✗ Main image is $IMAGE, expected nginx"
  exit 1
}
