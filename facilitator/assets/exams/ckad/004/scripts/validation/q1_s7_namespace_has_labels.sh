#!/bin/bash
# Q1.7 - Namespace has labels
# Points: 2

kubectl get namespace ckad-ns-a -o jsonpath='{.metadata.labels}' 2>/dev/null | grep -q '{}' && {
  echo "✓ Namespace has labels"
  exit 0
} || {
  echo "✗ Namespace missing labels"
  exit 1
}
