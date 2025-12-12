#!/bin/bash
# Q16.02 - Service exists
# Points: 2

kubectl get service mysql -n q16 >/dev/null 2>&1 && {
  echo "✓ Service mysql exists"
  exit 0
} || {
  echo "✗ Service not found"
  exit 1
}
