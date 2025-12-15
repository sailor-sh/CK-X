#!/bin/bash
# Q9.5 - Job created pod successfully
# Points: 2

kubectl get pods -n batch-jobs -l job-name=batch-job --no-headers 2>/dev/null | grep -q 'Completed' && {
  echo "✓ Job created pod successfully"
  exit 0
} || {
  echo "✗ Job pod not created"
  exit 1
}
