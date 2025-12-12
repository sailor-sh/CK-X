#!/bin/bash
# Q17.02 - Job completed successfully
# Points: 2

SUCCESS=$(kubectl get job compute-job -n q17 -o jsonpath='{.status.succeeded}' 2>/dev/null)
[[ "$SUCCESS" == "1" ]] && {
  echo "✓ Job succeeded"
  exit 0
} || {
  echo "✗ Success status: $SUCCESS, expected 1"
  exit 1
}
