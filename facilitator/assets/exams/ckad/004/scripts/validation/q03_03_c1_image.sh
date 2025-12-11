#!/bin/bash
# Q03.03 - Container c1 uses nginx
# Points: 2

IMAGE=$(kubectl get pod multi-box -n q03 -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
[[ "$IMAGE" =~ nginx ]] && {
  echo "✓ Container c1 uses nginx"
  exit 0
} || {
  echo "✗ Container c1 image is $IMAGE, expected nginx"
  exit 1
}
