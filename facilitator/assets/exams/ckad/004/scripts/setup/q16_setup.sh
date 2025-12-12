#!/bin/bash
set -e

NAMESPACE="q016"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create headless service for StatefulSet
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: $NAMESPACE
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
EOF

# Create StatefulSet
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  namespace: $NAMESPACE
spec:
  serviceName: mysql
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:5.7
        ports:
        - containerPort: 3306
          name: mysql
EOF

echo "✓ Q016 setup complete: StatefulSet with headless service created in namespace $NAMESPACE"
