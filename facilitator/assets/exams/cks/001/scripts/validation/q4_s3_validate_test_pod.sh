#!/bin/bash
# Validate that the test pod exists

POD_NAME="test-pod"
NAMESPACE="metadata-protect"

# Check if pod exists
kubectl get pod $POD_NAME -n $NAMESPACE &> /dev/null
if [ $? -ne 0 ]; then
  echo "❌ Pod '$POD_NAME' not found in namespace '$NAMESPACE'"
  exit 1
fi

# Check if pod is running
POD_STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
  echo "❌ Pod '$POD_NAME' is not in Running state (current state: $POD_STATUS)"
  exit 1
fi

# Check if pod uses the busybox image as required
POD_IMAGE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].image}')
if [[ "$POD_IMAGE" != *"busybox"* ]]; then
  echo "❌ Pod '$POD_NAME' is not using the busybox image (current image: $POD_IMAGE)"
  exit 1
fi

# kubectl run puts the command in args unless --command is supplied.
POD_COMMAND=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].command} {.spec.containers[0].args}')
if [[ "$POD_COMMAND" != *"sleep"* ]]; then
  echo "❌ Pod '$POD_NAME' is not running sleep command"
  exit 1
fi

echo "✅ Test pod exists and is correctly configured"
exit 0 