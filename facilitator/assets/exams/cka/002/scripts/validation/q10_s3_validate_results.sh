#!/bin/bash
set -e

# Check if results file exists in the pod
FILE_CHECK=$(kubectl exec -n dns-config dns-tester -- test -f /tmp/dns-test.txt && echo "exists" || echo "not found")
if [ "$FILE_CHECK" = "not found" ]; then
    echo "DNS test results file not found"
    exit 1
fi

# Check if file has content
CONTENT=$(kubectl exec -n dns-config dns-tester -- cat /tmp/dns-test.txt 2>/dev/null || echo "")
if [ -z "$CONTENT" ]; then
    echo "DNS test results file is empty"
    exit 1
fi

# Verify file contains required information
if ! echo "$CONTENT" | grep -q "dns-svc.dns-config.svc.cluster.local"; then
    echo "FQDN resolution results not found in file"
    exit 1
fi

exit 0 