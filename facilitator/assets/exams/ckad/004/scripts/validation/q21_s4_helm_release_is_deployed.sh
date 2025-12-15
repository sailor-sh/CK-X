#!/bin/bash
# Q21.4 - Helm release is deployed
# Points: 2

helm list -n helm-operations 2>/dev/null | grep -q 'nginx' && {
  echo "✓ Helm release is deployed"
  exit 0
} || {
  echo "✗ Helm release not deployed"
  exit 1
}
