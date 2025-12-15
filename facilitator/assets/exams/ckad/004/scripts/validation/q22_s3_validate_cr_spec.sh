#!/bin/bash
# Q22.03 - Custom Resource spec matches requirements
# Points: 2

NS="crds"
# As spec is not strictly defined in the question, verify apiVersion/kind are correct for the CR instance
AV=$(kubectl get backup my-backup -n "$NS" -o jsonpath='{.apiVersion}' 2>/dev/null)
KIND=$(kubectl get backup my-backup -n "$NS" -o jsonpath='{.kind}' 2>/dev/null)
if echo "$AV" | grep -q "stable.example.com/v1" && [ "$KIND" = "Backup" ]; then
  echo "✓ Custom Resource apiVersion/kind are correct"
  exit 0
else
  echo "✗ Custom Resource apiVersion/kind mismatch (apiVersion=$AV, kind=$KIND)"
  exit 1
fi

