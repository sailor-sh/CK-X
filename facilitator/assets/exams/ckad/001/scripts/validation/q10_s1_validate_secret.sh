#!/bin/bash

# Validate if the Secret 'db-credentials' exists in the 'workloads' namespace with correct data
USERNAME=$(kubectl get secret db-credentials -n workloads -o jsonpath='{.data.username}' 2>/dev/null | base64 --decode)
PASSWORD=$(kubectl get secret db-credentials -n workloads -o jsonpath='{.data.password}' 2>/dev/null | base64 --decode)
RANDOM=$(kubectl get secret db-credentials -n workloads -o jsonpath='{.data.random}' 2>/dev/null | base64 --decode)

if [ "$USERNAME" = "admin" ] && [ "$PASSWORD" = "securepass" ] && [ "$RANDOM" = "true" ]; then
    echo "Success: Secret 'db-credentials' exists with correct data"
    exit 0
else
    echo "Error: Secret 'db-credentials' does not have the correct data."
    echo "Expected: username=admin, password=securepass, random=true"
    echo "Found: username=$USERNAME, password=$PASSWORD, random=$RANDOM"
    exit 1
fi