#!/bin/bash
# Validate that Helm is properly installed in the cluster

# Check if helm command is available
command -v helm > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Helm command not found. Please install Helm."
  exit 1
fi

# Check helm version to ensure it's working
HELM_VERSION=$(helm version --short 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$HELM_VERSION" ]; then
  echo "❌ Helm is installed but not working properly. Check Helm installation."
  exit 1
fi

echo "✅ Helm is correctly installed (version: $HELM_VERSION)"

# Check if the Bitnami repository is added
BITNAMI_REPO=$(helm repo list 2>/dev/null | grep -i bitnami | wc -l)
if [ $BITNAMI_REPO -eq 0 ]; then
  echo "⚠️  Bitnami repository is not added to Helm. Add it with: helm repo add bitnami https://charts.bitnami.com/bitnami"
else
  echo "✅ Bitnami repository is properly configured"
fi

# Check if helm can access the Kubernetes cluster
HELM_LIST=$(helm list -A 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ Helm cannot access the Kubernetes cluster. Check Kubernetes configuration."
  exit 1
fi

echo "✅ Helm can successfully communicate with the Kubernetes cluster"
exit 0 