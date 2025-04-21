#!/bin/bash
set -e

# Check web deployment
kubectl get deployment web -n network || {
    echo "Deployment web not found in namespace network"
    exit 1
}

# Check api deployment
kubectl get deployment api -n network || {
    echo "Deployment api not found in namespace network"
    exit 1
}

# Check db deployment
kubectl get deployment db -n network || {
    echo "Deployment db not found in namespace network"
    exit 1
}

# Check web deployment configuration
WEB_IMAGE=$(kubectl get deployment web -n network -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ ! "$WEB_IMAGE" =~ "nginx" ]]; then
    echo "Web deployment is not using nginx image"
    exit 1
fi

WEB_LABEL=$(kubectl get deployment web -n network -o jsonpath='{.spec.template.metadata.labels.app}')
if [[ "$WEB_LABEL" != "web" ]]; then
    echo "Web deployment does not have correct label app=web"
    exit 1
fi

# Check api deployment configuration
API_IMAGE=$(kubectl get deployment api -n network -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ ! "$API_IMAGE" =~ "nginx" ]]; then
    echo "API deployment is not using nginx image"
    exit 1
fi

API_LABEL=$(kubectl get deployment api -n network -o jsonpath='{.spec.template.metadata.labels.app}')
if [[ "$API_LABEL" != "api" ]]; then
    echo "API deployment does not have correct label app=api"
    exit 1
fi

# Check db deployment configuration
DB_IMAGE=$(kubectl get deployment db -n network -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ ! "$DB_IMAGE" =~ "postgres" ]]; then
    echo "DB deployment is not using postgres image"
    exit 1
fi

DB_LABEL=$(kubectl get deployment db -n network -o jsonpath='{.spec.template.metadata.labels.app}')
if [[ "$DB_LABEL" != "db" ]]; then
    echo "DB deployment does not have correct label app=db"
    exit 1
fi

# Check if all pods are running
for DEPLOY in web api db; do
    READY_PODS=$(kubectl get deployment $DEPLOY -n network -o jsonpath='{.status.readyReplicas}')
    if [[ -z "$READY_PODS" ]] || [[ "$READY_PODS" -lt 1 ]]; then
        echo "Deployment $DEPLOY has no ready pods"
        exit 1
    fi
done

echo "Deployments validation successful"
exit 0 