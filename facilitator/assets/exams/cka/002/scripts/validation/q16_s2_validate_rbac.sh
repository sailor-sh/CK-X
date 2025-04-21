#!/bin/bash
set -e

# Check if Role exists
kubectl get role app-admin -n cluster-admin || {
    echo "Role app-admin not found in namespace cluster-admin"
    exit 1
}

# Check Role permissions for pods and deployments
RULES=$(kubectl get role app-admin -n cluster-admin -o json)

# Check list, get, watch permissions for pods and deployments
POD_RULES=$(echo "$RULES" | jq -r '.rules[] | select(.resources[] | contains("pods"))')
DEPLOYMENT_RULES=$(echo "$RULES" | jq -r '.rules[] | select(.resources[] | contains("deployments"))')

if [[ ! "$POD_RULES" =~ "list" ]] || [[ ! "$POD_RULES" =~ "get" ]] || [[ ! "$POD_RULES" =~ "watch" ]]; then
    echo "Missing required permissions for pods"
    exit 1
fi

if [[ ! "$DEPLOYMENT_RULES" =~ "list" ]] || [[ ! "$DEPLOYMENT_RULES" =~ "get" ]] || [[ ! "$DEPLOYMENT_RULES" =~ "watch" ]] || [[ ! "$DEPLOYMENT_RULES" =~ "update" ]]; then
    echo "Missing required permissions for deployments"
    exit 1
fi

# Check configmap permissions
CONFIGMAP_RULES=$(echo "$RULES" | jq -r '.rules[] | select(.resources[] | contains("configmaps"))')
if [[ ! "$CONFIGMAP_RULES" =~ "create" ]] || [[ ! "$CONFIGMAP_RULES" =~ "delete" ]]; then
    echo "Missing required permissions for configmaps"
    exit 1
fi

# Check if RoleBinding exists
kubectl get rolebinding app-admin -n cluster-admin || {
    echo "RoleBinding app-admin not found in namespace cluster-admin"
    exit 1
}

# Check if RoleBinding references correct Role and ServiceAccount
ROLE_REF=$(kubectl get rolebinding app-admin -n cluster-admin -o jsonpath='{.roleRef.name}')
if [[ "$ROLE_REF" != "app-admin" ]]; then
    echo "RoleBinding references incorrect Role. Expected app-admin, got $ROLE_REF"
    exit 1
fi

SA_REF=$(kubectl get rolebinding app-admin -n cluster-admin -o jsonpath='{.subjects[0].name}')
if [[ "$SA_REF" != "app-admin" ]]; then
    echo "RoleBinding references incorrect ServiceAccount. Expected app-admin, got $SA_REF"
    exit 1
fi

echo "RBAC validation successful"
exit 0 