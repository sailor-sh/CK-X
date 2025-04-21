#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment app-scheduling -n scheduling || {
    echo "Deployment app-scheduling not found in namespace scheduling"
    exit 1
}

# Check replicas
REPLICAS=$(kubectl get deployment app-scheduling -n scheduling -o jsonpath='{.spec.replicas}')
if [[ "$REPLICAS" != "3" ]]; then
    echo "Incorrect number of replicas. Expected 3, got $REPLICAS"
    exit 1
fi

# Check if using node affinity (not node selector)
NODE_SELECTOR=$(kubectl get deployment app-scheduling -n scheduling -o jsonpath='{.spec.template.spec.nodeSelector}')
if [[ -n "$NODE_SELECTOR" ]]; then
    echo "Deployment is using nodeSelector instead of nodeAffinity"
    exit 1
fi

# Check node affinity configuration
AFFINITY_TYPE=$(kubectl get deployment app-scheduling -n scheduling -o jsonpath='{.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution}')
if [[ -z "$AFFINITY_TYPE" ]]; then
    echo "Deployment is not using requiredDuringSchedulingIgnoredDuringExecution"
    exit 1
fi

# Check affinity rule
AFFINITY_KEY=$(kubectl get deployment app-scheduling -n scheduling -o jsonpath='{.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key}')
AFFINITY_VALUE=$(kubectl get deployment app-scheduling -n scheduling -o jsonpath='{.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]}')

if [[ "$AFFINITY_KEY" != "disk" ]] || [[ "$AFFINITY_VALUE" != "ssd" ]]; then
    echo "Incorrect node affinity configuration. Expected disk=ssd"
    exit 1
fi

echo "Node affinity validation successful"
exit 0 