#!/bin/bash
set -e

# Get pod nodes
HIGH_NODE=$(kubectl get pod high-priority -n scheduling -o jsonpath='{.spec.nodeName}')
LOW_NODE=$(kubectl get pod low-priority -n scheduling -o jsonpath='{.spec.nodeName}')

# Check if pods are on different nodes
if [[ "$HIGH_NODE" == "$LOW_NODE" ]]; then
    echo "Pods are scheduled on the same node: $HIGH_NODE"
    exit 1
fi

# Check anti-affinity configuration for high priority pod
HIGH_AFFINITY=$(kubectl get pod high-priority -n scheduling -o json | jq -r '.spec.affinity.podAntiAffinity')
if [[ -z "$HIGH_AFFINITY" ]]; then
    echo "High priority pod does not have pod anti-affinity configured"
    exit 1
fi

# Check anti-affinity configuration for low priority pod
LOW_AFFINITY=$(kubectl get pod low-priority -n scheduling -o json | jq -r '.spec.affinity.podAntiAffinity')
if [[ -z "$LOW_AFFINITY" ]]; then
    echo "Low priority pod does not have pod anti-affinity configured"
    exit 1
fi

# Check if anti-affinity is using the correct topology key
HIGH_TOPOLOGY=$(kubectl get pod high-priority -n scheduling -o jsonpath='{.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}')
if [[ "$HIGH_TOPOLOGY" != "kubernetes.io/hostname" ]]; then
    echo "High priority pod using incorrect topology key"
    exit 1
fi

LOW_TOPOLOGY=$(kubectl get pod low-priority -n scheduling -o jsonpath='{.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}')
if [[ "$LOW_TOPOLOGY" != "kubernetes.io/hostname" ]]; then
    echo "Low priority pod using incorrect topology key"
    exit 1
fi

echo "Anti-affinity validation successful"
exit 0 