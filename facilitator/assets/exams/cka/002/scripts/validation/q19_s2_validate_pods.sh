#!/bin/bash
set -e

# Check high priority pod
kubectl get pod high-priority -n scheduling || {
    echo "Pod high-priority not found in namespace scheduling"
    exit 1
}

# Check low priority pod
kubectl get pod low-priority -n scheduling || {
    echo "Pod low-priority not found in namespace scheduling"
    exit 1
}

# Check high priority pod configuration
HIGH_PRIORITY_CLASS=$(kubectl get pod high-priority -n scheduling -o jsonpath='{.spec.priorityClassName}')
if [[ "$HIGH_PRIORITY_CLASS" != "high-priority" ]]; then
    echo "High priority pod not using correct PriorityClass"
    exit 1
fi

# Check low priority pod configuration
LOW_PRIORITY_CLASS=$(kubectl get pod low-priority -n scheduling -o jsonpath='{.spec.priorityClassName}')
if [[ "$LOW_PRIORITY_CLASS" != "low-priority" ]]; then
    echo "Low priority pod not using correct PriorityClass"
    exit 1
fi

# Check if pods are running
for POD in high-priority low-priority; do
    STATUS=$(kubectl get pod $POD -n scheduling -o jsonpath='{.status.phase}')
    if [[ "$STATUS" != "Running" ]]; then
        echo "Pod $POD is not running. Current status: $STATUS"
        exit 1
    fi
done

echo "Pods validation successful"
exit 0 