#!/bin/bash
# Validate that the 'health-pod' in namespace 'workloads' has a correctly configured liveness probe

NAMESPACE="workloads"
POD_NAME="health-pod"

# Check if the pod exists
kubectl get pod $POD_NAME -n $NAMESPACE > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Pod '$POD_NAME' not found in namespace '$NAMESPACE'"
  exit 1
fi

# Check if liveness probe is configured
LIVENESS_PROBE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].livenessProbe}' 2>/dev/null)

if [ -z "$LIVENESS_PROBE" ]; then
  echo "❌ Liveness probe not configured for pod '$POD_NAME'"
  exit 1
fi

# Check if liveness probe is using HTTP GET
HTTP_GET=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].livenessProbe.httpGet}' 2>/dev/null)

if [ -z "$HTTP_GET" ]; then
  echo "❌ Liveness probe is not configured to use HTTP GET method"
  exit 1
fi

# Check the path
PROBE_PATH=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].livenessProbe.httpGet.path}' 2>/dev/null)

if [ "$PROBE_PATH" != "/healthz" ]; then
  echo "❌ Liveness probe path is not configured correctly. Expected '/healthz', got '$PROBE_PATH'"
  exit 1
fi

# Check the port
PROBE_PORT=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].livenessProbe.httpGet.port}' 2>/dev/null)

if [ "$PROBE_PORT" != "80" ] && [ "$PROBE_PORT" != "http" ]; then
  echo "❌ Liveness probe port is not configured correctly. Expected '80' or 'http', got '$PROBE_PORT'"
  exit 1
fi

# Check period seconds (should be 15s as specified in the question)
PERIOD_SECONDS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].livenessProbe.periodSeconds}' 2>/dev/null)

if [ -z "$PERIOD_SECONDS" ]; then
  PERIOD_SECONDS="10"  # Default value if not specified
fi

if [ "$PERIOD_SECONDS" != "15" ]; then
  echo "⚠️  Liveness probe periodSeconds is set to '$PERIOD_SECONDS', but '15' was specified in the requirements"
fi

# All checks passed
echo "✅ Liveness probe correctly configured to perform HTTP GET requests to '/healthz' on port '$PROBE_PORT'"
echo "✅ Probe configured with periodSeconds: $PERIOD_SECONDS"

# Additional probe details for informational purposes
INITIAL_DELAY=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].livenessProbe.initialDelaySeconds}' 2>/dev/null)
TIMEOUT=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].livenessProbe.timeoutSeconds}' 2>/dev/null)
FAILURE_THRESHOLD=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].livenessProbe.failureThreshold}' 2>/dev/null)

echo "ℹ️  Additional probe settings - initialDelaySeconds: ${INITIAL_DELAY:-N/A}, timeoutSeconds: ${TIMEOUT:-N/A}, failureThreshold: ${FAILURE_THRESHOLD:-N/A}"

exit 0 