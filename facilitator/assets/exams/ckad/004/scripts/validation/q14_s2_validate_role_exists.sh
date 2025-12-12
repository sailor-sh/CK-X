#!/bin/bash
# Q14.02 - Role exists
# Points: 2

kubectl get role app-role -n service-accounts >/dev/null 2>&1 && {
  echo "✓ Role app-role exists"
  exit 0
} || {
  echo "✗ Role not found"
  exit 1
}
