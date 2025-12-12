#!/bin/bash
# Q03.04 - Container c2 uses busybox
# Points: 2

IMAGE=$(kubectl get pod multi-box -n q03 -o jsonpath='{.spec.containers[1].image}' 2>/dev/null)
[[ "$IMAGE" =~ busybox ]] && {
  echo "✓ Container c2 uses busybox"
  exit 0
} || {
  echo "✗ Container c2 image is $IMAGE, expected busybox"
  exit 1
}
