#!/bin/bash

# Create a test pod with the app-admin ServiceAccount
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: rbac-test-pod
  namespace: cluster-admin
spec:
  serviceAccountName: app-admin
  containers:
  - name: curl
    image: curlimages/curl
    command: ["sleep", "3600"]
EOF

# Wait for pod to be running
for i in {1..30}; do
  if kubectl get pod rbac-test-pod -n cluster-admin | grep -q Running; then
    break
  fi
  sleep 2
done

# Test pod operations (should succeed)
LIST_PODS=$(kubectl auth can-i list pods --as=system:serviceaccount:cluster-admin:app-admin -n cluster-admin)
GET_PODS=$(kubectl auth can-i get pods --as=system:serviceaccount:cluster-admin:app-admin -n cluster-admin)
WATCH_PODS=$(kubectl auth can-i watch pods --as=system:serviceaccount:cluster-admin:app-admin -n cluster-admin)

# Test deployment operations (should succeed)
LIST_DEPLOY=$(kubectl auth can-i list deployments --as=system:serviceaccount:cluster-admin:app-admin -n cluster-admin)
GET_DEPLOY=$(kubectl auth can-i get deployments --as=system:serviceaccount:cluster-admin:app-admin -n cluster-admin)
UPDATE_DEPLOY=$(kubectl auth can-i update deployments --as=system:serviceaccount:cluster-admin:app-admin -n cluster-admin)

# Test configmap operations (should succeed)
CREATE_CM=$(kubectl auth can-i create configmaps --as=system:serviceaccount:cluster-admin:app-admin -n cluster-admin)
DELETE_CM=$(kubectl auth can-i delete configmaps --as=system:serviceaccount:cluster-admin:app-admin -n cluster-admin)

# Clean up
kubectl delete pod rbac-test-pod -n cluster-admin --force --grace-period=0 2>/dev/null || true

# Check all permissions are correct
if [[ "$LIST_PODS" == "yes" && \
      "$GET_PODS" == "yes" && \
      "$WATCH_PODS" == "yes" && \
      "$LIST_DEPLOY" == "yes" && \
      "$GET_DEPLOY" == "yes" && \
      "$UPDATE_DEPLOY" == "yes" && \
      "$CREATE_CM" == "yes" && \
      "$DELETE_CM" == "yes" ]]; then
    exit 0
else
    exit 1
fi 