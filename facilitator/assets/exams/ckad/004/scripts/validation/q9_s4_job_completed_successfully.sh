#!/bin/bash
# Q9.4 - Job completed successfully
# Points: 2

kubectl get job batch-job -n batch-jobs -o jsonpath='{.status.succeeded}' 2>/dev/null | grep -q '1' && {
  echo "✓ Job completed successfully"
  exit 0
} || {
  echo "✗ Job not completed"
  exit 1
}
