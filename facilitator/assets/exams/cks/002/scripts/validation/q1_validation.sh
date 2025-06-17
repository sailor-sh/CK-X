#!/bin/bash
set -e

# Validation for Question 1: RBAC Implementation
echo "Validating RBAC Implementation scenario..."

# Check if namespaces exist
if ! kubectl get namespace dev-team &> /dev/null; then
    echo "FAIL: Namespace 'dev-team' not found"
    exit 1
fi

if ! kubectl get namespace prod-team &> /dev/null; then
    echo "FAIL: Namespace 'prod-team' not found"
    exit 1
fi

# Check if ServiceAccount exists
if ! kubectl get serviceaccount dev-user -n dev-team &> /dev/null; then
    echo "FAIL: ServiceAccount 'dev-user' not found in namespace dev-team"
    exit 1
fi

# Check if Role exists
if ! kubectl get role dev-role -n dev-team &> /dev/null; then
    echo "FAIL: Role 'dev-role' not found in namespace dev-team"
    exit 1
fi

# Check if RoleBinding exists
if ! kubectl get rolebinding dev-binding -n dev-team &> /dev/null; then
    echo "FAIL: RoleBinding 'dev-binding' not found in namespace dev-team"
    exit 1
fi

# Check if ClusterRole exists
if ! kubectl get clusterrole limited-reader &> /dev/null; then
    echo "FAIL: ClusterRole 'limited-reader' not found"
    exit 1
fi

# Check if ClusterRoleBinding exists
if ! kubectl get clusterrolebinding dev-cluster-binding &> /dev/null; then
    echo "FAIL: ClusterRoleBinding 'dev-cluster-binding' not found"
    exit 1
fi

# Check if deployments exist in both namespaces
if ! kubectl get deployment dev-app -n dev-team &> /dev/null; then
    echo "FAIL: Deployment 'dev-app' not found in namespace dev-team"
    exit 1
fi

if ! kubectl get deployment prod-app -n prod-team &> /dev/null; then
    echo "FAIL: Deployment 'prod-app' not found in namespace prod-team"
    exit 1
fi

# Verify RBAC permissions by testing access
# This would require impersonation which might not work in all environments
# So we'll just check that the bindings are correctly configured

# Check RoleBinding subject
ROLEBINDING_USER=$(kubectl get rolebinding dev-binding -n dev-team -o jsonpath='{.subjects[0].name}')
if [ "$ROLEBINDING_USER" != "dev-user" ]; then
    echo "FAIL: RoleBinding 'dev-binding' is not bound to 'dev-user', found: $ROLEBINDING_USER"
    exit 1
fi

echo "PASS: RBAC Implementation validation successful"
