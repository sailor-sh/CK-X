#!/bin/bash
set -e

NAMESPACE="q004"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create ConfigMap
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: $NAMESPACE
data:
  app.properties: |
    database.host=localhost
    database.port=5432
EOF

# Create Secret
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  namespace: $NAMESPACE
type: Opaque
data:
  username: YWRtaW4=
  password: cGFzc3dvcmQxMjM=
EOF

echo "✓ Q004 setup complete: ConfigMap and Secret created in namespace $NAMESPACE"
