#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q17
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"
mkdir -p /opt/course/exam3/q17
cat >/opt/course/exam3/q17/test-init-container.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-init-container
  namespace: ckad-q17
spec:
  replicas: 1
  selector:
    matchLabels: { app: test-init-container }
  template:
    metadata:
      labels: { app: test-init-container }
    spec:
      volumes:
      - name: site
        emptyDir: {}
      containers:
      - name: nginx
        image: nginx:1.17.3-alpine
        volumeMounts:
        - name: site
          mountPath: /usr/share/nginx/html
EOF
kubectl apply -f /opt/course/exam3/q17/test-init-container.yaml
echo "Seeded base deployment and yaml for ${NS}."
