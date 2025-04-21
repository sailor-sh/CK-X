#!/bin/bash
set -e

# Check high priority class
kubectl get priorityclass high-priority || {
    echo "PriorityClass high-priority not found"
    exit 1
}

# Check low priority class
kubectl get priorityclass low-priority || {
    echo "PriorityClass low-priority not found"
    exit 1
}

# Check high priority value
HIGH_VALUE=$(kubectl get priorityclass high-priority -o jsonpath='{.value}')
if [[ "$HIGH_VALUE" != "1000" ]]; then
    echo "Incorrect priority value for high-priority. Expected 1000, got $HIGH_VALUE"
    exit 1
fi

# Check low priority value
LOW_VALUE=$(kubectl get priorityclass low-priority -o jsonpath='{.value}')
if [[ "$LOW_VALUE" != "100" ]]; then
    echo "Incorrect priority value for low-priority. Expected 100, got $LOW_VALUE"
    exit 1
fi

# Check that neither is set as default
HIGH_DEFAULT=$(kubectl get priorityclass high-priority -o jsonpath='{.globalDefault}')
LOW_DEFAULT=$(kubectl get priorityclass low-priority -o jsonpath='{.globalDefault}')

if [[ "$HIGH_DEFAULT" == "true" ]] || [[ "$LOW_DEFAULT" == "true" ]]; then
    echo "PriorityClasses should not be set as default"
    exit 1
fi

echo "PriorityClass validation successful"
exit 0 