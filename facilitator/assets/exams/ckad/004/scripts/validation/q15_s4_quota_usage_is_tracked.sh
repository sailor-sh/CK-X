#!/bin/bash
# Q15.4 - Quota usage is tracked
# Points: 2

kubectl describe quota ns-quota -n resource-quotas 2>/dev/null | grep -q 'Used:' && {
  echo "✓ Quota usage is tracked"
  exit 0
} || {
  echo "✗ Quota usage not tracked"
  exit 1
}
