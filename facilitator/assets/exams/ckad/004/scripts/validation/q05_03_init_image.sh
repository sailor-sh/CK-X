#!/bin/bash
# Q05.03 - Init uses busybox
# Points: 2

IMAGE=$(kubectl get pod init-pod -n q05 -o jsonpath='{.spec.initContainers[0].image}' 2>/dev/null)
[[ "$IMAGE" =~ busybox ]] && {
  echo "✓ Init uses busybox"
  exit 0
} || {
  echo "✗ Init image is $IMAGE, expected busybox"
  exit 1
}
