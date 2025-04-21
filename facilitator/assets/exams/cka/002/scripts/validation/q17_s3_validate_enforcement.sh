#!/bin/bash
set -e

echo "🔎 Starting network policy validation..."

NAMESPACE="network"
CLIENT_POD="test-client"
IMAGE="curlimages/curl:8.5.0"

# 1. Ensure test-client exists
if ! kubectl get pod -n $NAMESPACE $CLIENT_POD &>/dev/null; then
    echo "🚀 Creating test-client pod..."
    kubectl run $CLIENT_POD -n $NAMESPACE --image=$IMAGE --restart=Never --command -- sleep 3600
    kubectl wait --for=condition=Ready pod/$CLIENT_POD -n $NAMESPACE --timeout=30s
else
    echo "ℹ️ $CLIENT_POD pod already exists, skipping creation"
fi

# 2. Test service connectivity using curl
echo "🔧 Testing service connectivity with curl..."

test_connection() {
    local target=$1
    local port=$2
    local expected=$3
    local url="http://$target:$port"

    echo "➡️ Testing: $CLIENT_POD ➡ $url (expected: $expected)"
    
    if kubectl exec -n $NAMESPACE $CLIENT_POD -- curl -s --max-time 2 $url &>/dev/null; then
        if [[ "$expected" == "fail" ]]; then
            echo "❌ FAILED: Connection to $url should be BLOCKED but SUCCEEDED"
            exit 1
        else
            echo "✅ Connection to $url succeeded"
        fi
    else
        if [[ "$expected" == "success" ]]; then
            echo "❌ FAILED: Connection to $url should be ALLOWED but FAILED"
            exit 1
        else
            echo "✅ Connection to $url correctly blocked"
        fi
    fi
}

# Run tests
test_connection api 80 success
test_connection db 5432 success
test_connection web 80 fail
test_connection db 80 fail
test_connection api 5432 fail

echo "🎉 All network policy tests passed successfully"
