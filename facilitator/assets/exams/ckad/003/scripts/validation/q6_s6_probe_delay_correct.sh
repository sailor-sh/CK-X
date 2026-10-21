#!/bin/bash
# Validator for Q6 - Probe Initial Delay
# Checks that readinessProbe.initialDelaySeconds is set to 5.
DELAY=$(kubectl get pod pod6 -n readiness -o jsonpath='{.spec.containers[0].readinessProbe.initialDelaySeconds}' 2>/dev/null)
if [ "$DELAY" == "5" ]; then
  exit 0
else
  exit 1
fi
