#!/bin/bash
# Q19.4 - Network policy is enforced
# Points: 2

kubectl describe networkpolicy default-deny -n network-policies 2>/dev/null | grep -q 'Policy:' && {
  echo "✓ Network policy is enforced"
  exit 0
} || {
  echo "✗ Network policy not enforced"
  exit 1
}
