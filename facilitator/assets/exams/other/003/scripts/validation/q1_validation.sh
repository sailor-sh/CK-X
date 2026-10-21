#!/bin/bash
set -e

# Validation for Question 1: Microservices Architecture Foundation
echo "Validating Microservices Architecture Foundation scenario..."

# Check if all required namespaces exist
REQUIRED_NAMESPACES=("microservices" "monitoring" "ingress-system" "cicd")
for ns in "${REQUIRED_NAMESPACES[@]}"; do
    if ! kubectl get namespace "$ns" &> /dev/null; then
        echo "FAIL: Namespace '$ns' not found"
        exit 1
    fi
done

# Check namespace labels
MICROSERVICES_LABEL=$(kubectl get namespace microservices -o jsonpath='{.metadata.labels.tier}')
if [ "$MICROSERVICES_LABEL" != "application" ]; then
    echo "FAIL: Namespace 'microservices' should have tier=application label"
    exit 1
fi

MONITORING_LABEL=$(kubectl get namespace monitoring -o jsonpath='{.metadata.labels.tier}')
if [ "$MONITORING_LABEL" != "infrastructure" ]; then
    echo "FAIL: Namespace 'monitoring' should have tier=infrastructure label"
    exit 1
fi

# Check if API Gateway deployment exists
if ! kubectl get deployment api-gateway -n microservices &> /dev/null; then
    echo "FAIL: Deployment 'api-gateway' not found in namespace microservices"
    exit 1
fi

# Check if User Service deployment exists
if ! kubectl get deployment user-service -n microservices &> /dev/null; then
    echo "FAIL: Deployment 'user-service' not found in namespace microservices"
    exit 1
fi

# Check if Order Service deployment exists
if ! kubectl get deployment order-service -n microservices &> /dev/null; then
    echo "FAIL: Deployment 'order-service' not found in namespace microservices"
    exit 1
fi

# Check if Redis deployment exists
if ! kubectl get deployment redis -n microservices &> /dev/null; then
    echo "FAIL: Deployment 'redis' not found in namespace microservices"
    exit 1
fi

# Check if services exist
REQUIRED_SERVICES=("api-gateway-service" "user-service" "order-service" "redis-service")
for svc in "${REQUIRED_SERVICES[@]}"; do
    if ! kubectl get service "$svc" -n microservices &> /dev/null; then
        echo "FAIL: Service '$svc' not found in namespace microservices"
        exit 1
    fi
done

# Check deployment readiness
API_GATEWAY_READY=$(kubectl get deployment api-gateway -n microservices -o jsonpath='{.status.readyReplicas}')
USER_SERVICE_READY=$(kubectl get deployment user-service -n microservices -o jsonpath='{.status.readyReplicas}')
ORDER_SERVICE_READY=$(kubectl get deployment order-service -n microservices -o jsonpath='{.status.readyReplicas}')

if [ "$API_GATEWAY_READY" != "2" ]; then
    echo "FAIL: API Gateway should have 2 ready replicas, found: $API_GATEWAY_READY"
    exit 1
fi

if [ "$USER_SERVICE_READY" != "2" ]; then
    echo "FAIL: User Service should have 2 ready replicas, found: $USER_SERVICE_READY"
    exit 1
fi

if [ "$ORDER_SERVICE_READY" != "2" ]; then
    echo "FAIL: Order Service should have 2 ready replicas, found: $ORDER_SERVICE_READY"
    exit 1
fi

# Check if NetworkPolicy exists
if ! kubectl get networkpolicy microservices-network-policy -n microservices &> /dev/null; then
    echo "FAIL: NetworkPolicy 'microservices-network-policy' not found in namespace microservices"
    exit 1
fi

echo "PASS: Microservices Architecture Foundation validation successful"
