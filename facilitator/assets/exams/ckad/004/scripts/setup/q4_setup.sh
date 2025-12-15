#!/bin/bash
set -e

NAMESPACE="sidecar-logging"

# Prepare only the namespace needed for the sidecar logging question
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Q4 setup complete: Namespace $NAMESPACE is ready"
