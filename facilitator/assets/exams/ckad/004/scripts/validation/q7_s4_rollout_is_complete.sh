#!/bin/bash
# Q7.4 - Rollout is complete
# Points: 2

kubectl rollout status deployment web-deploy -n rolling-updates 2>/dev/null | grep -q 'successfully rolled out' && {
  echo "✓ Rollout is complete"
  exit 0
} || {
  echo "✗ Rollout not complete"
  exit 1
}
