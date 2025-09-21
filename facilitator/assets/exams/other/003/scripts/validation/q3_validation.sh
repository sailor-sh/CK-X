#!/bin/bash
set -e

# Validation for Question 3: Distributed Configuration Management
echo "Validating Distributed Configuration Management scenario..."

# Check if namespace exists
if ! kubectl get namespace microservices &> /dev/null; then
    echo "FAIL: Namespace 'microservices' not found"
    exit 1
fi

# Check if etcd deployment exists
if ! kubectl get deployment etcd -n microservices &> /dev/null; then
    echo "FAIL: Deployment 'etcd' not found in namespace microservices"
    exit 1
fi

# Check if etcd service exists
if ! kubectl get service etcd-service -n microservices &> /dev/null; then
    echo "FAIL: Service 'etcd-service' not found in namespace microservices"
    exit 1
fi

# Check if config-manager deployment exists
if ! kubectl get deployment config-manager -n microservices &> /dev/null; then
    echo "FAIL: Deployment 'config-manager' not found in namespace microservices"
    exit 1
fi

# Check if config-manager service exists
if ! kubectl get service config-manager-service -n microservices &> /dev/null; then
    echo "FAIL: Service 'config-manager-service' not found in namespace microservices"
    exit 1
fi

# Check etcd readiness
ETCD_READY=$(kubectl get deployment etcd -n microservices -o jsonpath='{.status.readyReplicas}')
if [ "$ETCD_READY" != "1" ]; then
    echo "FAIL: etcd should have 1 ready replica, found: $ETCD_READY"
    exit 1
fi

# Check config-manager readiness
CONFIG_MANAGER_READY=$(kubectl get deployment config-manager -n microservices -o jsonpath='{.status.readyReplicas}')
if [ "$CONFIG_MANAGER_READY" != "1" ]; then
    echo "FAIL: Config Manager should have 1 ready replica, found: $CONFIG_MANAGER_READY"
    exit 1
fi

# Check if ConfigMaps exist for application configuration
REQUIRED_CONFIGMAPS=("app-config-prod" "app-config-dev" "database-config")
for cm in "${REQUIRED_CONFIGMAPS[@]}"; do
    if ! kubectl get configmap "$cm" -n microservices &> /dev/null; then
        echo "FAIL: ConfigMap '$cm' not found in namespace microservices"
        exit 1
    fi
done

# Check if Secrets exist for sensitive configuration
REQUIRED_SECRETS=("database-credentials" "api-keys" "jwt-secret")
for secret in "${REQUIRED_SECRETS[@]}"; do
    if ! kubectl get secret "$secret" -n microservices &> /dev/null; then
        echo "FAIL: Secret '$secret' not found in namespace microservices"
        exit 1
    fi
done

# Check if microservices are using the configuration
MICROSERVICES=("user-service" "order-service" "payment-service")
for ms in "${MICROSERVICES[@]}"; do
    if ! kubectl get deployment "$ms" -n microservices &> /dev/null; then
        echo "FAIL: Deployment '$ms' not found in namespace microservices"
        exit 1
    fi
    
    # Check if deployment is ready
    READY_REPLICAS=$(kubectl get deployment "$ms" -n microservices -o jsonpath='{.status.readyReplicas}')
    if [ "$READY_REPLICAS" != "1" ]; then
        echo "FAIL: Deployment '$ms' should have 1 ready replica, found: $READY_REPLICAS"
        exit 1
    fi
done

echo "PASS: Distributed Configuration Management validation successful"
