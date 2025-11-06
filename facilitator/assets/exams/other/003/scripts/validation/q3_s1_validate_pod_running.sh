#!/bin/bash
# Validate that the 'health-pod' is running in namespace 'workloads'

NAMESPACE="workloads"
POD_NAME="health-pod"

# Check if the pod exists
POD_STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}' 2>/dev/null)

if [ -z "$POD_STATUS" ]; then
  echo "❌ Pod '$POD_NAME' not found in namespace '$NAMESPACE'"
  exit 1
fi

# Check if the pod is running
if [ "$POD_STATUS" != "Running" ]; then
  echo "❌ Pod '$POD_NAME' exists but is not running (current status: $POD_STATUS)"
  
  # Get additional details about non-running pod
  CONTAINER_STATUSES=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.containerStatuses[*].state}' 2>/dev/null)
  
  if [ -n "$CONTAINER_STATUSES" ]; then
    echo "Container statuses: $CONTAINER_STATUSES"
  fi
  
  exit 1
fi

# Check if all containers are ready
READY_COUNT=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.containerStatuses[*].ready}' | grep -o "true" | wc -l)
CONTAINER_COUNT=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[*].name}' | wc -w)

if [ "$READY_COUNT" -ne "$CONTAINER_COUNT" ]; then
  echo "❌ Pod '$POD_NAME' is running, but not all containers are ready ($READY_COUNT of $CONTAINER_COUNT ready)"
  exit 1
fi

# All checks passed
echo "✅ Pod '$POD_NAME' is running successfully in namespace '$NAMESPACE'"
exit 0 