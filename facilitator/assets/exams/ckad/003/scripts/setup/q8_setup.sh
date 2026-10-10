#!/usr/bin/env bash
set -euo pipefail
kubectl get ns rollout >/dev/null 2>&1 || kubectl create ns rollout

# Create a working deployment and wait for it to be ready.
# This establishes an initial "good" revision in the history (rev 1).
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-new-c32
  namespace: rollout
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-new-c32
  template:
    metadata:
      labels:
        app: api-new-c32
    spec:
      containers:
      - name: api
        image: nginx:1.21.6-alpine
        ports:
        - containerPort: 80
EOF

# Wait for the initial deployment to be fully rolled out and ready.
kubectl -n rollout rollout status deployment/api-new-c32 --timeout=60s

# Create a second good revision (rev 2) with a different valid image, so rollback
# history is meaningful and not trivial.
kubectl -n rollout set image deploy/api-new-c32 api=nginx:1.23.4-alpine --record=true || true
kubectl -n rollout rollout status deployment/api-new-c32 --timeout=60s || true

# Force a broken latest revision (rev 3) by setting a non-existent image tag.
# Also set maxUnavailable=1 to ensure we don't keep the old pod running as a crutch,
# making the deployment clearly not Ready until the student rolls back.
kubectl -n rollout patch deploy/api-new-c32 \
  --type='merge' \
  -p '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxSurge":0,"maxUnavailable":1}}}}' >/dev/null 2>&1 || true

kubectl -n rollout set image deploy/api-new-c32 api=nginx:does-not-exist --record=true || true

# Ensure the bad image is actually set on the deployment template (idempotent)
current_img=$(kubectl -n rollout get deploy api-new-c32 -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
if [[ "$current_img" != *":does-not-exist" ]]; then
  kubectl -n rollout patch deploy/api-new-c32 \
    --type='json' \
    -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"nginx:does-not-exist"}]' >/dev/null 2>&1 || true
fi

# Give the controller a moment to observe the new generation and attempt rollout
sleep 2

mkdir -p /opt/course/exam3/q08
