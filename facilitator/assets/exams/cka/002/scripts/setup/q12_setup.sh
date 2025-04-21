#!/bin/bash
set -e

# Create namespace
kubectl create namespace kustomize --dry-run=client -o yaml | kubectl apply -f -

# Create directory structure for kustomize
mkdir -p /tmp/exam/kustomize/{base,overlays/production}

# Create initial base files
cat > /tmp/exam/kustomize/base/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
EOF

echo "Setup completed for Question 12" 