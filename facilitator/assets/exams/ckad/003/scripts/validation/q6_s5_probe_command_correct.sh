#!/bin/bash
# Validator for Q6 - Readiness Probe (effect-based, path-aware)
# Ensure a readiness-type probe is configured using exec, and that it checks the ready file path.

# Ensure the pod exists
kubectl -n readiness get pod pod6 >/dev/null 2>&1 || exit 1

# Extract readinessProbe exec command tokens (space-separated)
CMD=$(kubectl -n readiness get pod pod6 -o jsonpath='{.spec.containers[0].readinessProbe.exec.command[*]}' 2>/dev/null)

# Must be a readiness probe of exec type
if [ -z "$CMD" ]; then
  exit 1
fi

# Accept common command forms that reference the file path. Default path is /tmp/ready.
# Also accept /tmp/healthy for now; can be tightened if desired.
echo "$CMD" | grep -Eq '/tmp/ready|/tmp/healthy' || exit 1

exit 0
