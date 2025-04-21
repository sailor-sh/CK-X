#!/bin/bash
set -e

# Check if service exists
kubectl get service web-svc -n stateful || {
    echo "Service web-svc not found in namespace stateful"
    exit 1
}

# Check if it's a headless service
CLUSTER_IP=$(kubectl get service web-svc -n stateful -o jsonpath='{.spec.clusterIP}')
if [[ "$CLUSTER_IP" != "None" ]]; then
    echo "Service is not headless. ClusterIP should be None, got $CLUSTER_IP"
    exit 1
fi

# Check selector
SELECTOR=$(kubectl get service web-svc -n stateful -o jsonpath='{.spec.selector.app}')
if [[ "$SELECTOR" != "web" ]]; then
    echo "Incorrect service selector. Expected app=web, got app=$SELECTOR"
    exit 1
fi

# Check ports
PORT=$(kubectl get service web-svc -n stateful -o jsonpath='{.spec.ports[0].port}')
if [[ "$PORT" != "80" ]]; then
    echo "Incorrect port. Expected 80, got $PORT"
    exit 1
fi

# # Verify DNS records exist for pods
# for i in {0..2}; do
#     nslookup web-$i.web-svc.stateful.svc.cluster.local 2>/dev/null || {
#         echo "DNS record for web-$i.web-svc.stateful.svc.cluster.local not found"
#         exit 1
#     }
# done

echo "Headless service validation successful"
exit 0 