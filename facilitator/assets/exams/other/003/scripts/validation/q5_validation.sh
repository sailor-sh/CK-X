#!/bin/bash
set -e

# Validation for Question 5: API Gateway and Traffic Management
echo "Validating API Gateway and Traffic Management scenario..."

# Check if namespace exists
if ! kubectl get namespace microservices &> /dev/null; then
    echo "FAIL: Namespace 'microservices' not found"
    exit 1
fi

# Check if ingress-system namespace exists
if ! kubectl get namespace ingress-system &> /dev/null; then
    echo "FAIL: Namespace 'ingress-system' not found"
    exit 1
fi

# Check if NGINX Ingress Controller deployment exists
if ! kubectl get deployment nginx-ingress-controller -n ingress-system &> /dev/null; then
    echo "FAIL: Deployment 'nginx-ingress-controller' not found in namespace ingress-system"
    exit 1
fi

# Check if Istio Gateway exists (if using Istio)
if ! kubectl get gateway api-gateway -n microservices &> /dev/null; then
    echo "WARN: Gateway 'api-gateway' not found (may not be using Istio)"
fi

# Check if VirtualService exists (if using Istio)
if ! kubectl get virtualservice api-routes -n microservices &> /dev/null; then
    echo "WARN: VirtualService 'api-routes' not found (may not be using Istio)"
fi

# Check if Ingress resources exist
REQUIRED_INGRESSES=("api-ingress" "frontend-ingress")
for ingress in "${REQUIRED_INGRESSES[@]}"; do
    if ! kubectl get ingress "$ingress" -n microservices &> /dev/null; then
        echo "FAIL: Ingress '$ingress' not found in namespace microservices"
        exit 1
    fi
done

# Check NGINX Ingress Controller readiness
NGINX_READY=$(kubectl get deployment nginx-ingress-controller -n ingress-system -o jsonpath='{.status.readyReplicas}')
if [ "$NGINX_READY" != "2" ]; then
    echo "FAIL: NGINX Ingress Controller should have 2 ready replicas, found: $NGINX_READY"
    exit 1
fi

# Check if rate limiting is configured
if ! kubectl get configmap nginx-configuration -n ingress-system &> /dev/null; then
    echo "FAIL: ConfigMap 'nginx-configuration' not found in namespace ingress-system"
    exit 1
fi

# Check if TLS certificates are configured
API_INGRESS_TLS=$(kubectl get ingress api-ingress -n microservices -o jsonpath='{.spec.tls[0].secretName}')
if [ -z "$API_INGRESS_TLS" ]; then
    echo "FAIL: Ingress 'api-ingress' should have TLS configuration"
    exit 1
fi

# Check if the TLS secret exists
if ! kubectl get secret "$API_INGRESS_TLS" -n microservices &> /dev/null; then
    echo "FAIL: TLS Secret '$API_INGRESS_TLS' not found in namespace microservices"
    exit 1
fi

# Check if backend services are available
BACKEND_SERVICES=("user-service" "order-service" "payment-service")
for svc in "${BACKEND_SERVICES[@]}"; do
    if ! kubectl get service "$svc" -n microservices &> /dev/null; then
        echo "FAIL: Service '$svc' not found in namespace microservices"
        exit 1
    fi
    
    # Check service endpoints
    ENDPOINTS=$(kubectl get endpoints "$svc" -n microservices -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)
    if [ "$ENDPOINTS" -eq 0 ]; then
        echo "FAIL: Service '$svc' has no endpoints"
        exit 1
    fi
done

echo "PASS: API Gateway and Traffic Management validation successful"
