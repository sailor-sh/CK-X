#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q16
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"
kubectl -n "$NS" delete deploy cleaner --ignore-not-found=true
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cleaner
  namespace: ckad-q16
spec:
  replicas: 1
  selector:
    matchLabels: { app: cleaner }
  template:
    metadata:
      labels: { app: cleaner }
    spec:
      containers:
      - name: cleaner-con
        image: busybox:1.31.0
        command: ["sh","-c","mkdir -p /var/log/cleaner && while true; do date >> /var/log/cleaner/cleaner.log; sleep 2; done"]
        volumeMounts:
        - name: logvol
          mountPath: /var/log/cleaner
      volumes:
      - name: logvol
        emptyDir: {}
EOF
echo "Seeded Deployment cleaner in ${NS}."
