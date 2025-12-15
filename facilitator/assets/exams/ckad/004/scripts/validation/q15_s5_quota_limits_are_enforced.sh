#!/bin/bash
# Q15.5 - Quota limits are enforced
# Points: 2

kubectl describe quota ns-quota -n resource-quotas 2>/dev/null | grep -q 'Limits:' && {
  echo "✓ Quota limits are enforced"
  exit 0
} || {
  echo "✗ Quota limits not enforced"
  exit 1
}
