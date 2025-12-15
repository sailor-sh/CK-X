#!/bin/bash
# Q04.07 - Sidecar is properly logging
# Points: 2

SIDECAR_LOGS=$(kubectl logs logger-pod -n sidecar-logging -c sidecar 2>/dev/null | wc -l)
[[ $SIDECAR_LOGS -gt 0 ]] && {
  echo "✓ Sidecar is properly logging"
  exit 0
} || {
  echo "✗ Sidecar not logging"
  exit 1
}
