#!/bin/bash
set -e

# Check if tester pod exists and is running
POD_STATUS=$(kubectl get pod dns-tester -n dns-config -o jsonpath='{.status.phase}' 2>/dev/null || echo "not found")
if [ "$POD_STATUS" = "not found" ]; then
    echo "DNS tester pod not found"
    exit 1
fi

if [ "$POD_STATUS" != "Running" ]; then
    echo "DNS tester pod is not running"
    exit 1
fi

# Test DNS resolution
TEST_RESULT=$(kubectl exec -n dns-config dns-tester -- nslookup dns-svc 2>/dev/null || echo "failed")
if echo "$TEST_RESULT" | grep -q "failed"; then
    echo "DNS resolution test failed"
    exit 1
fi

# Test FQDN resolution
TEST_RESULT=$(kubectl exec -n dns-config dns-tester -- nslookup dns-svc.dns-config.svc.cluster.local 2>/dev/null || echo "failed")
if echo "$TEST_RESULT" | grep -q "failed"; then
    echo "FQDN DNS resolution test failed"
    exit 1
fi

exit 0 