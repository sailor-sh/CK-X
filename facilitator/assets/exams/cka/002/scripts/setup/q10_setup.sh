#!/bin/bash
set -e

# Create namespace
kubectl create namespace dns-config --dry-run=client -o yaml | kubectl apply -f -

# Create directory for test results if it doesn't exist
mkdir -p /tmp/dns-test

echo "Setup completed for Question 10" 