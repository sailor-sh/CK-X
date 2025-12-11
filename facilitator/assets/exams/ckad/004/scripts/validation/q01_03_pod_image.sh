#!/bin/bash
# Q01.03 - Pod uses nginx:alpine image
# Points: 2

IMAGE=$(kubectl get pod web-core -n ckad-ns-a -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
[[ "$IMAGE" == "nginx:alpine" ]] && {
  echo "✓ Pod uses nginx:alpine image"
  exit 0
} || {
  echo "✗ Pod image is $IMAGE, expected nginx:alpine"
  exit 1
}
