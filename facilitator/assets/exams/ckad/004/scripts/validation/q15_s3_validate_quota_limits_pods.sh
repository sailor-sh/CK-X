#!/bin/bash
# Q15.03 - ResourceQuota limits pods to 5
# Points: 4

VAL=$(kubectl get resourcequota ns-quota -n quota-ns -o jsonpath='{.spec.hard.pods}' 2>/dev/null)
if [ "$VAL" = "5" ] || [ "$VAL" = "5"$'\n' ]; then
  echo "✓ ResourceQuota limits pods to 5"
  exit 0
else
  echo "✗ ResourceQuota pods hard limit is '$VAL', expected '5'"
  exit 1
fi

