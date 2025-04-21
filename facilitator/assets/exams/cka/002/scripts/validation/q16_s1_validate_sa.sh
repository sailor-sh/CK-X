#!/bin/bash
set -e

# Check if ServiceAccount exists
kubectl get serviceaccount app-admin -n cluster-admin || {
    echo "ServiceAccount app-admin not found in namespace cluster-admin"
    exit 1
}

# Check if token is automatically mounted
AUTO_MOUNT=$(kubectl get serviceaccount app-admin -n cluster-admin -o jsonpath='{.automountServiceAccountToken}')
if [[ "$AUTO_MOUNT" == "false" ]]; then
    echo "ServiceAccount token automounting is disabled"
    exit 1
fi

# Check if secret is created for the ServiceAccount
# SECRET_NAME=$(kubectl get serviceaccount app-admin -n cluster-admin -o jsonpath='{.secrets[0].name}')
# if [[ -z "$SECRET_NAME" ]]; then
#     echo "No token secret found for ServiceAccount"
#     exit 1
# fi

# # Verify secret exists
# kubectl get secret $SECRET_NAME -n cluster-admin || {
#     echo "Token secret $SECRET_NAME not found"
#     exit 1
# }

echo "ServiceAccount validation successful"
exit 0 