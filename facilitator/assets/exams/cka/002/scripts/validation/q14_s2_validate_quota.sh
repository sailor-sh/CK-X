#!/bin/bash
set -e

# Check if ResourceQuota exists
kubectl get resourcequota -n limits || {
    echo "No ResourceQuota found in namespace limits"
    exit 1
}

# Check CPU quota
CPU_QUOTA=$(kubectl get resourcequota -n limits -o jsonpath='{.items[0].spec.hard.cpu}')
if [[ "$CPU_QUOTA" != "2" ]]; then
    echo "Incorrect CPU quota. Expected 2, got $CPU_QUOTA"
    exit 1
fi

# Check memory quota
MEM_QUOTA=$(kubectl get resourcequota -n limits -o jsonpath='{.items[0].spec.hard.memory}')
if [[ "$MEM_QUOTA" != "2Gi" ]]; then
    echo "Incorrect memory quota. Expected 2Gi, got $MEM_QUOTA"
    exit 1
fi

# Check pod quota
POD_QUOTA=$(kubectl get resourcequota -n limits -o jsonpath='{.items[0].spec.hard.pods}')
if [[ "$POD_QUOTA" != "5" ]]; then
    echo "Incorrect pod quota. Expected 5, got $POD_QUOTA"
    exit 1
fi

# Check if quota is being enforced
QUOTA_STATUS=$(kubectl get resourcequota -n limits -o jsonpath='{.items[0].status.used}')
if [[ -z "$QUOTA_STATUS" ]]; then
    echo "ResourceQuota is not being enforced"
    exit 1
fi

echo "ResourceQuota validation successful"
exit 0 