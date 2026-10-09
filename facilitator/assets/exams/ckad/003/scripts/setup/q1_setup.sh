#!/bin/bash
set -e

# Setup for Question 1: Multi-Container Pod Patterns
echo "Setting up environment for Multi-Container Pod scenario..."

# Create namespace
kubectl create namespace microservices --dry-run=client -o yaml | kubectl apply -f -

# Create a ConfigMap for the sidecar container
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: sidecar-config
  namespace: microservices
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/app/*.log
      pos_file /var/log/fluentd-app.log.pos
      tag app.logs
      format json
    </source>
    <match app.logs>
      @type stdout
    </match>
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: microservices
data:
  app.properties: |
    server.port=8080
    logging.level.root=INFO
    logging.file.path=/var/log/app/
EOF

echo "Environment setup completed for Question 1 - Multi-Container Pods"
