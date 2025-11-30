#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q14
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"
kubectl -n "$NS" delete pod secret-handler --ignore-not-found=true
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secret-handler
  namespace: ckad-q14
spec:
  containers:
  - name: handler
    image: busybox:1.31.0
    command: ["sh","-c","sleep 1d"]
    volumeMounts:
    - name: secret2
      mountPath: /tmp/secret2
  volumes:
  - name: secret2
    emptyDir: {}
EOF
echo "Seeded Pod secret-handler in ${NS}."
