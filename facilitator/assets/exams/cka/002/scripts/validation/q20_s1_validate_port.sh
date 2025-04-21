#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment failing-app -n troubleshoot || {
    echo "Deployment failing-app not found in namespace troubleshoot"
    exit 1
}

# Check container port configuration
PORT=$(kubectl get deployment failing-app -n troubleshoot -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}')
if [[ "$PORT" != "80" ]]; then
    echo "Incorrect container port. Expected 80, got $PORT"
    exit 1
fi

# Check if port is correctly configured in pods
PODS=$(kubectl get pods -n troubleshoot -l app=failing-app -o jsonpath='{.items[*].metadata.name}')
for POD in $PODS; do
    POD_PORT=$(kubectl get pod $POD -n troubleshoot -o jsonpath='{.spec.containers[0].ports[0].containerPort}')
    if [[ "$POD_PORT" != "80" ]]; then
        echo "Pod $POD has incorrect port configuration. Expected 80, got $POD_PORT"
        exit 1
    fi
done

echo "Container port validation successful"
exit 0 