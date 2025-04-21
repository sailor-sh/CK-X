#!/bin/bash
set -e

# Check if LimitRange exists
kubectl get limitrange -n limits || {
    echo "No LimitRange found in namespace limits"
    exit 1
}

# Check default request
CPU_REQUEST=$(kubectl get limitrange -n limits -o jsonpath='{.items[0].spec.limits[?(@.type=="Container")].defaultRequest.cpu}')
if [[ "$CPU_REQUEST" != "100m" ]]; then
    echo "Incorrect default CPU request. Expected 100m, got $CPU_REQUEST"
    exit 1
fi

MEM_REQUEST=$(kubectl get limitrange -n limits -o jsonpath='{.items[0].spec.limits[?(@.type=="Container")].defaultRequest.memory}')
if [[ "$MEM_REQUEST" != "128Mi" ]]; then
    echo "Incorrect default memory request. Expected 128Mi, got $MEM_REQUEST"
    exit 1
fi

# Check default limit
CPU_LIMIT=$(kubectl get limitrange -n limits -o jsonpath='{.items[0].spec.limits[?(@.type=="Container")].default.cpu}')
if [[ "$CPU_LIMIT" != "200m" ]]; then
    echo "Incorrect default CPU limit. Expected 200m, got $CPU_LIMIT"
    exit 1
fi

MEM_LIMIT=$(kubectl get limitrange -n limits -o jsonpath='{.items[0].spec.limits[?(@.type=="Container")].default.memory}')
if [[ "$MEM_LIMIT" != "256Mi" ]]; then
    echo "Incorrect default memory limit. Expected 256Mi, got $MEM_LIMIT"
    exit 1
fi

# Check max limit
MAX_CPU=$(kubectl get limitrange -n limits -o jsonpath='{.items[0].spec.limits[?(@.type=="Container")].max.cpu}')
if [[ "$MAX_CPU" != "500m" ]]; then
    echo "Incorrect max CPU limit. Expected 500m, got $MAX_CPU"
    exit 1
fi

MAX_MEM=$(kubectl get limitrange -n limits -o jsonpath='{.items[0].spec.limits[?(@.type=="Container")].max.memory}')
if [[ "$MAX_MEM" != "512Mi" ]]; then
    echo "Incorrect max memory limit. Expected 512Mi, got $MAX_MEM"
    exit 1
fi

echo "LimitRange validation successful"
exit 0 