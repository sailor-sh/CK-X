#!/bin/bash
# Q8.3 - Rollback history available
# Points: 2

kubectl rollout history deployment web-deploy -n rollbacks 2>/dev/null | wc -l | grep -q '[2-9]' && {
  echo "✓ Rollback history available"
  exit 0
} || {
  echo "✗ No rollback history"
  exit 1
}
