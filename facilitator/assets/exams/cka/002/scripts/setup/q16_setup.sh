#!/bin/bash
set -e

# Create namespace
kubectl create namespace cluster-admin --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 16" 