#!/bin/bash
# Q21.02 - Helm release my-web installed
# Points: 4

helm list -n helm-ns | grep -q "my-web" && {
  echo "✓ Helm release my-web installed"
  exit 0
} || {
  echo "✗ Helm release my-web not found"
  exit 1
}