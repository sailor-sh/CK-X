#!/bin/bash
set -e

# Check if test pod exists
kubectl get pod dns-test -n dns-debug || {
    echo "Pod dns-test not found in namespace dns-debug"
    exit 1
}

# Check if pod is running
POD_STATUS=$(kubectl get pod dns-test -n dns-debug -o jsonpath='{.status.phase}')
if [[ "$POD_STATUS" != "Running" ]]; then
    echo "Pod is not in Running state. Current state: $POD_STATUS"
    exit 1
fi

# Test service DNS resolution
kubectl exec dns-test -n dns-debug -- wget -qO- http://web-svc || {
    echo "Failed to resolve service DNS: web-svc.dns-debug.svc.cluster.local"
    exit 1
}

# Test service DNS resolution
kubectl exec dns-test -n dns-debug -- wget -qO- http://web-svc.dns-debug.svc.cluster.local || {
    echo "Failed to resolve service DNS: web-svc.dns-debug.svc.cluster.local"
    exit 1
}

# Test pod DNS resolution (for first pod)
# POD_IP=$(kubectl get pod -l app=web-app -n dns-debug -o jsonpath='{.items[0].status.podIP}')
# POD_IP_REVERSED=$(echo $POD_IP | awk -F. '{print $4"."$3"."$2"."$1}')
# kubectl exec dns-test -n dns-debug -- nslookup $POD_IP_REVERSED.in-addr.arpa || {
#     echo "Failed to resolve pod DNS"
#     exit 1
# }

echo "DNS resolution validation successful"
exit 0 