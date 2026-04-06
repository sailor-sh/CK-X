#!/bin/bash
# Validator for Q6 - Probe Period
# Checks that readinessProbe.periodSeconds is set to 10.
PERIOD=$(kubectl get pod pod6 -n readiness -o jsonpath='{.spec.containers[0].readinessProbe.periodSeconds}' 2>/dev/null)
if [ "$PERIOD" == "10" ]; then
  exit 0
else
  exit 1
fi
