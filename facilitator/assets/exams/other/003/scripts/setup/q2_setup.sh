#!/bin/bash

# Setup for Question 2: Troubleshoot and fix a broken deployment

# Create the app namespace if it doesn't exist already
if ! kubectl get namespace app &> /dev/null; then
    kubectl create namespace app
fi

# Delete any existing deployment with the same name
kubectl delete deployment nice-app -n app --ignore-not-found=true

# Create a deployment with nginx webserver
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nice-app
  namespace: app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nice-app
  template:
    metadata:
      labels:
        app: nice-app
    spec:
      containers:
      - name: app
        image: nginx:latest
        ports:
        - containerPort: 80
EOF

# Create a service for the deployment with wrong selector
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nice-app
  name: nice-app
  namespace: app
spec:
  ports:
  - name: nginx
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nive-app
  type: ClusterIP
status:
  loadBalancer: {}
EOF

# Create a test pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: curl-test-pod
  namespace: app
spec:
  containers:
  - name: curl
    image: curlimages/curl
    command: ["sleep", "3600"]
EOF

echo "Setup complete for Question 2: Created broken deployment 'nice-app' in namespace 'app'"
exit 0