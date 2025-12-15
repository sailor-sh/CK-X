#!/bin/bash
# Q13.03 - Read-only root filesystem
# Points: 3

NS="security-contexts"
RO=$(kubectl get pod secure-pod -n "$NS" -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null)
if [ "$RO" = "true" ]; then
  echo "✓ Container has readOnlyRootFilesystem=true"
  exit 0
else
  echo "✗ readOnlyRootFilesystem is '$RO', expected 'true'"
  exit 1
fi

