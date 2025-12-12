#!/bin/bash
# Q17.05 - Job pod ran to completion
# Points: 2

TIME=$(kubectl get job compute-job -n q17 -o jsonpath='{.status.completionTime}' 2>/dev/null)
[[ -n "$TIME" ]] && {
  echo "✓ Job completed"
  exit 0
} || {
  echo "✗ Not completed"
  exit 1
}
