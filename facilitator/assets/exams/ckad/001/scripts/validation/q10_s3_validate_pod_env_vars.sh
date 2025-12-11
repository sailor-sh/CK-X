#!/bin/bash

# Validate if the pod 'secure-pod' has the correct environment variables from Secret
POD_NAME="secure-pod"
NAMESPACE="workloads"

# Expected secret name and keys
EXPECTED_SECRET="db-credentials"
EXPECTED_USER_KEY="username"
EXPECTED_PASSWORD_KEY="password"
EXPECTED_RANDOM_KEY="random"

# Extract secret name and key used for DB_USER
DB_USER_SECRET=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath="{.spec.containers[0].env[?(@.name=='DB_USER')].valueFrom.secretKeyRef.name}")
DB_USER_KEY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath="{.spec.containers[0].env[?(@.name=='DB_USER')].valueFrom.secretKeyRef.key}")

# Extract secret name and key used for DB_PASSWORD
DB_PASSWORD_SECRET=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath="{.spec.containers[0].env[?(@.name=='DB_PASSWORD')].valueFrom.secretKeyRef.name}")
DB_PASSWORD_KEY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath="{.spec.containers[0].env[?(@.name=='DB_PASSWORD')].valueFrom.secretKeyRef.key}")

# Extract secret name and key used for MYSQL_RANDOM_ROOT_PASSWORD
MYSQL_RANDOM_ROOT_PASSWORD_SECRET=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath="{.spec.containers[0].env[?(@.name=='MYSQL_RANDOM_ROOT_PASSWORD')].valueFrom.secretKeyRef.name}")
MYSQL_RANDOM_ROOT_PASSWORD_KEY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath="{.spec.containers[0].env[?(@.name=='MYSQL_RANDOM_ROOT_PASSWORD')].valueFrom.secretKeyRef.key}")

# Validate all
if [[ "$DB_USER_SECRET" == "$EXPECTED_SECRET" && "$DB_USER_KEY" == "$EXPECTED_USER_KEY" &&
      "$DB_PASSWORD_SECRET" == "$EXPECTED_SECRET" && "$DB_PASSWORD_KEY" == "$EXPECTED_PASSWORD_KEY" &&
      "$MYSQL_RANDOM_ROOT_PASSWORD_SECRET" == "$EXPECTED_SECRET" && "$MYSQL_RANDOM_ROOT_PASSWORD_KEY" == "$EXPECTED_RANDOM_KEY" ]]; then
    echo "✅ Success: Pod '$POD_NAME' has correct secret name and keys for env variables"
    exit 0
else
    echo "❌ Error: Pod '$POD_NAME' does not have the correct secret configuration"
    echo "DB_USER -> Secret: $DB_USER_SECRET, Key: $DB_USER_KEY"
    echo "DB_PASSWORD -> Secret: $DB_PASSWORD_SECRET, Key: $DB_PASSWORD_KEY"
    exit 1
fi
