#!/bin/bash
set -e

# Check if HPA exists
kubectl get hpa -n scaling scaling-app || {
    echo "HorizontalPodAutoscaler scaling-app not found in namespace scaling"
    exit 1
}

# Check min replicas
MIN_REPLICAS=$(kubectl get hpa -n scaling scaling-app -o jsonpath='{.spec.minReplicas}')
if [[ "$MIN_REPLICAS" != "2" ]]; then
    echo "Incorrect minimum replicas. Expected 2, got $MIN_REPLICAS"
    exit 1
fi

# Check max replicas
MAX_REPLICAS=$(kubectl get hpa -n scaling scaling-app -o jsonpath='{.spec.maxReplicas}')
if [[ "$MAX_REPLICAS" != "5" ]]; then
    echo "Incorrect maximum replicas. Expected 5, got $MAX_REPLICAS"
    exit 1
fi

# Check target CPU utilization
TARGET_CPU=$(kubectl get hpa -n scaling scaling-app -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}')
if [[ "$TARGET_CPU" != "70" ]]; then
    echo "Incorrect target CPU utilization. Expected 70, got $TARGET_CPU"
    exit 1
fi

# Check if HPA is targeting the correct deployment
TARGET_REF=$(kubectl get hpa -n scaling scaling-app -o jsonpath='{.spec.scaleTargetRef.name}')
if [[ "$TARGET_REF" != "scaling-app" ]]; then
    echo "HPA is not targeting the correct deployment. Expected scaling-app, got $TARGET_REF"
    exit 1
fi

echo "HPA validation successful"
exit 0 