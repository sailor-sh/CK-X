#!/bin/bash
# Q14.03 - RoleBinding exists
# Points: 2

kubectl get rolebinding app-rolebinding -n q14 >/dev/null 2>&1 && {
  echo "✓ RoleBinding app-rolebinding exists"
  exit 0
} || {
  echo "✗ RoleBinding not found"
  exit 1
}
