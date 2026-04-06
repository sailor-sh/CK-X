#!/usr/bin/env bash
set -euo pipefail
# Verifies that curling the service returns 'check this out!'
# First, get the pod name
POD_NAME=$(kubectl -n init-container get pod -l app=init-web -o jsonpath='{.items[0].metadata.name}')

# Check if pod is ready
POD_STATUS=$(kubectl -n init-container get pod $POD_NAME -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "Pod is not running, status: $POD_STATUS"
    exit 1
fi

# Try to curl the service from within the pod (with timeout and retry)
for i in 1 2 3; do
    CURL_RESULT=$(kubectl -n init-container exec $POD_NAME -- curl -s -m 5 http://localhost 2>/dev/null || echo "")
    if [[ "$CURL_RESULT" == *"check this out!"* ]]; then
        echo "Curl validation successful"
        exit 0
    fi
    sleep 2
 done

echo "Curl result does not contain expected content after retries. Last result: $CURL_RESULT"
echo "Debug: Checking if index.html exists in the pod..."
kubectl -n init-container exec $POD_NAME -- ls -la /usr/share/nginx/html/
exit 1