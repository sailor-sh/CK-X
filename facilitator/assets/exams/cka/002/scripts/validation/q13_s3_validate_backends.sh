#!/bin/bash
set -e

# Check app1 deployment and service
kubectl get deployment app1 -n gateway || {
    echo "Deployment app1 not found in namespace gateway"
    exit 1
}

kubectl get service app1-svc -n gateway || {
    echo "Service app1-svc not found in namespace gateway"
    exit 1
}

# Check app2 deployment and service
kubectl get deployment app2 -n gateway || {
    echo "Deployment app2 not found in namespace gateway"
    exit 1
}

kubectl get service app2-svc -n gateway || {
    echo "Service app2-svc not found in namespace gateway"
    exit 1
}

# Check if services are configured correctly
for SVC in app1-svc app2-svc; do
    # Check port
    PORT=$(kubectl get service $SVC -n gateway -o jsonpath='{.spec.ports[0].port}')
    if [[ "$PORT" != "8080" ]]; then
        echo "Service $SVC has incorrect port. Expected 8080, got $PORT"
        exit 1
    fi
    
    # Check if pods are running
    APP_NAME=${SVC%-svc}
    READY_PODS=$(kubectl get deployment $APP_NAME -n gateway -o jsonpath='{.status.readyReplicas}')
    if [[ -z "$READY_PODS" ]] || [[ "$READY_PODS" -lt 1 ]]; then
        echo "No ready pods found for deployment $APP_NAME"
        exit 1
    fi
    
    # Check if service endpoints exist
    ENDPOINTS=$(kubectl get endpoints $SVC -n gateway -o jsonpath='{.subsets[0].addresses}')
    if [[ -z "$ENDPOINTS" ]]; then
        echo "No endpoints found for service $SVC"
        exit 1
    fi
done

echo "Backend services validation successful"
exit 0 