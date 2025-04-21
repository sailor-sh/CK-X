#!/bin/bash
set -e

NAMESPACE="kustomize"

# Find the full name of the nginx-config ConfigMap
CONFIGMAP_NAME=$(kubectl get configmap -n $NAMESPACE --no-headers | awk '/^nginx-config-/ {print $1; exit}')

if [[ -z "$CONFIGMAP_NAME" ]]; then
  echo "ConfigMap starting with nginx-config not found in namespace $NAMESPACE"
  exit 1
fi

echo "Found ConfigMap: $CONFIGMAP_NAME"

# Check ConfigMap content
CONFIG_CONTENT=$(kubectl get configmap "$CONFIGMAP_NAME" -n $NAMESPACE -o jsonpath='{.data.index\.html}')
if [[ "$CONFIG_CONTENT" != "Welcome to Production" ]]; then
    echo "Incorrect ConfigMap content. Expected 'Welcome to Production', got '$CONFIG_CONTENT'"
    exit 1
fi

# Check if ConfigMap is mounted in pods
MOUNT_PATH=$(kubectl get deployment nginx -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[?(@.name=="nginx-index")].mountPath}')
if [[ -z "$MOUNT_PATH" ]]; then
    echo "ConfigMap not mounted in deployment"
    exit 1
fi

# Check if volume is configured correctly
VOLUME_NAME=$(kubectl get deployment nginx -n $NAMESPACE -o jsonpath="{.spec.template.spec.volumes[?(@.configMap.name==\"$CONFIGMAP_NAME\")].name}")
if [[ -z "$VOLUME_NAME" ]]; then
    echo "ConfigMap volume not configured correctly in deployment"
    exit 1
fi

echo "ConfigMap validation successful"
exit 0
