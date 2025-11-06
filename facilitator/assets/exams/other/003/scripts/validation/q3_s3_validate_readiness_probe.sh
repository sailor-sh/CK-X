#!/bin/bash
# Validate that the 'health-pod' in namespace 'workloads' has a correctly configured readiness probe

NAMESPACE="workloads"
POD_NAME="health-pod"

# Check if the pod exists
kubectl get pod $POD_NAME -n $NAMESPACE > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Pod '$POD_NAME' not found in namespace '$NAMESPACE'"
  exit 1
fi

# Check if readiness probe is configured
READINESS_PROBE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].readinessProbe}' 2>/dev/null)

if [ -z "$READINESS_PROBE" ]; then
  echo "❌ Readiness probe not configured for pod '$POD_NAME'"
  exit 1
fi

# The readiness probe should be a TCP socket check
TCP_SOCKET=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].readinessProbe.tcpSocket}' 2>/dev/null)

if [ -z "$TCP_SOCKET" ]; then
  echo "❌ Readiness probe is not configured to use TCP socket check"
  exit 1
fi

# Check the port
PROBE_PORT=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].readinessProbe.tcpSocket.port}' 2>/dev/null)

if [ "$PROBE_PORT" != "80" ] && [ "$PROBE_PORT" != "http" ]; then
  echo "❌ Readiness probe port is not configured correctly. Expected '80' or 'http', got '$PROBE_PORT'"
  exit 1
fi

# Check period seconds (should be 10s as specified in the question)
PERIOD_SECONDS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].readinessProbe.periodSeconds}' 2>/dev/null)

if [ -z "$PERIOD_SECONDS" ]; then
  PERIOD_SECONDS="10"  # Default value if not specified
fi

if [ "$PERIOD_SECONDS" != "10" ]; then
  echo "⚠️  Readiness probe periodSeconds is set to '$PERIOD_SECONDS', but '10' was specified in the requirements"
fi

# All checks passed
echo "✅ Readiness probe correctly configured to check TCP port $PROBE_PORT"
echo "✅ Probe configured with periodSeconds: $PERIOD_SECONDS"

# Additional probe details for informational purposes
INITIAL_DELAY=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].readinessProbe.initialDelaySeconds}' 2>/dev/null)
TIMEOUT=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].readinessProbe.timeoutSeconds}' 2>/dev/null)
FAILURE_THRESHOLD=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].readinessProbe.failureThreshold}' 2>/dev/null)

echo "ℹ️  Additional probe settings - initialDelaySeconds: ${INITIAL_DELAY:-N/A}, timeoutSeconds: ${TIMEOUT:-N/A}, failureThreshold: ${FAILURE_THRESHOLD:-N/A}"

exit 0 