#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q15
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"
kubectl -n "$NS" delete deploy web-moon --ignore-not-found=true
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-moon
  namespace: ckad-q15
spec:
  replicas: 1
  selector:
    matchLabels: { app: web-moon }
  template:
    metadata:
      labels: { app: web-moon }
    spec:
      containers:
      - name: nginx
        image: nginx:1.17.3-alpine
        volumeMounts:
        - name: webcontent
          mountPath: /usr/share/nginx/html
      volumes:
      - name: webcontent
        configMap:
          name: configmap-web-moon-html
          items:
          - key: index.html
            path: index.html
EOF
echo "Seeded Deployment web-moon in ${NS}."
