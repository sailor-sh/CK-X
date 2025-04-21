#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment failing-app -n troubleshoot || {
    echo "Deployment failing-app not found in namespace troubleshoot"
    exit 1
}

# Check liveness probe configuration
PROBE_PORT=$(kubectl get deployment failing-app -n troubleshoot -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.port}')
if [[ "$PROBE_PORT" != "80" ]]; then
    echo "Incorrect liveness probe port. Expected 80, got $PROBE_PORT"
    exit 1
fi

# Check if probe is configured in pods
PODS=$(kubectl get pods -n troubleshoot -l app=failing-app -o jsonpath='{.items[*].metadata.name}')
for POD in $PODS; do
    POD_PROBE_PORT=$(kubectl get pod $POD -n troubleshoot -o jsonpath='{.spec.containers[0].livenessProbe.httpGet.port}')
    if [[ "$POD_PROBE_PORT" != "80" ]]; then
        echo "Pod $POD has incorrect liveness probe port. Expected 80, got $POD_PROBE_PORT"
        exit 1
    fi
    
    # Check if pod is being restarted due to failed liveness probe
    RESTARTS=$(kubectl get pod $POD -n troubleshoot -o jsonpath='{.status.containerStatuses[0].restartCount}')
    LAST_STATE=$(kubectl get pod $POD -n troubleshoot -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}')
    
    if [[ "$LAST_STATE" == "LivenessProbe" ]]; then
        echo "Pod $POD is failing due to liveness probe"
        exit 1
    fi
done

echo "Liveness probe validation successful"
exit 0 