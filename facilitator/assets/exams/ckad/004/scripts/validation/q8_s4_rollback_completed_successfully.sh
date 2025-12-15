#!/bin/bash
# Q8.4 - Rollback completed successfully
# Points: 2

kubectl rollout status deployment web-deploy -n rollbacks 2>/dev/null | grep -q 'successfully rolled out' && {
  echo "✓ Rollback completed successfully"
  exit 0
} || {
  echo "✗ Rollback not complete"
  exit 1
}
