#!/bin/bash

# Check if PVCs for StatefulSet exist and are bound
PVC_COUNT=$(kubectl get pvc -n database | grep mysql-storage | grep Bound | wc -l)

if [[ $PVC_COUNT -eq 2 ]]; then
    exit 0
else
    exit 1
fi
