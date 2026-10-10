#!/usr/bin/env bash
set -euo pipefail
# Verifies the service is reachable on the specified NodePort from within the cluster
# Get the nodeport
NODEPORT=$(kubectl -n nodeport-30100 get svc jupiter-crew-svc -o jsonpath='{.spec.ports[0].nodePort}')

# Get a pod name to test from
TEST_POD=$(kubectl -n nodeport-30100 get pod -l app=jupiter -o jsonpath='{.items[0].metadata.name}')

# Try to curl the service on the nodeport (using localhost in single-node clusters)
CURL_RESULT=$(kubectl -n nodeport-30100 exec $TEST_POD -- curl -s -m 5 http://localhost:$NODEPORT)

if [ -z "$CURL_RESULT" ]; then
    echo "Service is not reachable on nodeport $NODEPORT"
    exit 1
fi