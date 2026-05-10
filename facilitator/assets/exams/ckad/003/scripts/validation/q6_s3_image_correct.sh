#!/bin/bash
# Validator for Q6 - Container Image
# Checks if the container is using the correct image.
IMAGE=$(kubectl get pod pod6 -n readiness -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
if [ "$IMAGE" == "busybox:1.31.0" ]; then
  exit 0
else
  exit 1
fi
