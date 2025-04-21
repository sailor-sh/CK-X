#!/bin/bash
set -e

# Check if HPA exists
kubectl get hpa -n monitoring resource-consumer || {
    echo "HorizontalPodAutoscaler resource-consumer not found in namespace monitoring"
    exit 1
}

# Check min replicas
MIN_REPLICAS=$(kubectl get hpa -n monitoring resource-consumer -o jsonpath='{.spec.minReplicas}')
if [[ "$MIN_REPLICAS" != "3" ]]; then
    echo "Incorrect minimum replicas. Expected 3, got $MIN_REPLICAS"
    exit 1
fi

# Check max replicas
MAX_REPLICAS=$(kubectl get hpa -n monitoring resource-consumer -o jsonpath='{.spec.maxReplicas}')
if [[ "$MAX_REPLICAS" != "6" ]]; then
    echo "Incorrect maximum replicas. Expected 6, got $MAX_REPLICAS"
    exit 1
fi

# Check target CPU utilization
TARGET_CPU=$(kubectl get hpa resource-consumer -n monitoring -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}')
if [[ "$TARGET_CPU" != "50" ]]; then
    echo "Incorrect target CPU utilization. Expected 50, got $TARGET_CPU"
    exit 1
fi

# Check if HPA is targeting the correct deployment
TARGET_REF=$(kubectl get hpa -n monitoring resource-consumer -o jsonpath='{.spec.scaleTargetRef.name}')
if [[ "$TARGET_REF" != "resource-consumer" ]]; then
    echo "HPA is not targeting the correct deployment. Expected resource-consumer, got $TARGET_REF"
    exit 1
fi

echo "HPA validation successful"
exit 0 