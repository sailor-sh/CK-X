#!/bin/bash
# Q16.01 - StatefulSet exists
# Points: 2

kubectl get statefulset mysql -n q16 >/dev/null 2>&1 && {
  echo "✓ StatefulSet mysql exists"
  exit 0
} || {
  echo "✗ StatefulSet not found"
  exit 1
}
