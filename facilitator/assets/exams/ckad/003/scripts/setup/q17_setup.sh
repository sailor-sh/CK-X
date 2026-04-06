#!/usr/bin/env bash
set -euo pipefail
mkdir -p /opt/course/exam3/q17
kubectl get ns init-container >/dev/null 2>&1 || kubectl create ns init-container

cat > /opt/course/exam3/q17/test-init-container.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-init-container
  namespace: init-container
spec:
  replicas: 1
  selector:
    matchLabels: {app: init-web}
  template:
    metadata:
      labels: {app: init-web}
    spec:
      containers:
      - name: web
        image: nginx:1.17.3-alpine
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        emptyDir: {}
EOF

kubectl apply -f /opt/course/exam3/q17/test-init-container.yaml
