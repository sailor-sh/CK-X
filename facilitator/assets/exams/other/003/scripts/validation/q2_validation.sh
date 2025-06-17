#!/bin/bash
set -e

# Validation for Question 2: Service Discovery and Load Balancing
echo "Validating Service Discovery and Load Balancing scenario..."

# Check if namespace exists
if ! kubectl get namespace microservices &> /dev/null; then
    echo "FAIL: Namespace 'microservices' not found"
    exit 1
fi

# Check if Consul deployment exists
if ! kubectl get deployment consul -n microservices &> /dev/null; then
    echo "FAIL: Deployment 'consul' not found in namespace microservices"
    exit 1
fi

# Check if Consul service exists
if ! kubectl get service consul-service -n microservices &> /dev/null; then
    echo "FAIL: Service 'consul-service' not found in namespace microservices"
    exit 1
fi

# Check if HAProxy deployment exists
if ! kubectl get deployment haproxy -n microservices &> /dev/null; then
    echo "FAIL: Deployment 'haproxy' not found in namespace microservices"
    exit 1
fi

# Check if HAProxy service exists
if ! kubectl get service haproxy-service -n microservices &> /dev/null; then
    echo "FAIL: Service 'haproxy-service' not found in namespace microservices"
    exit 1
fi

# Check if load balancer service exists
if ! kubectl get service load-balancer -n microservices &> /dev/null; then
    echo "FAIL: Service 'load-balancer' not found in namespace microservices"
    exit 1
fi

# Check Consul readiness
CONSUL_READY=$(kubectl get deployment consul -n microservices -o jsonpath='{.status.readyReplicas}')
if [ "$CONSUL_READY" != "1" ]; then
    echo "FAIL: Consul should have 1 ready replica, found: $CONSUL_READY"
    exit 1
fi

# Check HAProxy readiness
HAPROXY_READY=$(kubectl get deployment haproxy -n microservices -o jsonpath='{.status.readyReplicas}')
if [ "$HAPROXY_READY" != "2" ]; then
    echo "FAIL: HAProxy should have 2 ready replicas, found: $HAPROXY_READY"
    exit 1
fi

# Check if ConfigMap for HAProxy exists
if ! kubectl get configmap haproxy-config -n microservices &> /dev/null; then
    echo "FAIL: ConfigMap 'haproxy-config' not found in namespace microservices"
    exit 1
fi

# Check if backend services are properly registered
BACKEND_SERVICES=("backend-service-1" "backend-service-2" "backend-service-3")
for svc in "${BACKEND_SERVICES[@]}"; do
    if ! kubectl get service "$svc" -n microservices &> /dev/null; then
        echo "FAIL: Service '$svc' not found in namespace microservices"
        exit 1
    fi
done

# Check service endpoints
for svc in "${BACKEND_SERVICES[@]}"; do
    ENDPOINTS=$(kubectl get endpoints "$svc" -n microservices -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)
    if [ "$ENDPOINTS" -eq 0 ]; then
        echo "FAIL: Service '$svc' has no endpoints"
        exit 1
    fi
done

echo "PASS: Service Discovery and Load Balancing validation successful"
