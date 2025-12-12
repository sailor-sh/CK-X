#!/bin/bash
# Q14.04 - Binding references correct role
# Points: 2

ROLE=$(kubectl get rolebinding app-rolebinding -n q14 -o jsonpath='{.roleRef.name}' 2>/dev/null)
[[ "$ROLE" == "app-role" ]] && {
  echo "✓ Binding references app-role"
  exit 0
} || {
  echo "✗ Binding references $ROLE, expected app-role"
  exit 1
}
