#!/bin/bash

# Question 2 Setup: Service Discovery and Load Balancing
# Deploy core microservices with service discovery

set -e

echo "Setting up Service Discovery and Load Balancing..."

# Deploy User Service
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: microservices
  labels:
    app: user-service
    tier: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
        tier: backend
    spec:
      serviceAccountName: microservice-sa
      containers:
      - name: user-service
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        env:
        - name: SERVICE_NAME
          value: "user-service"
        - name: SERVICE_PORT
          value: "80"
        envFrom:
        - configMapRef:
            name: microservice-config
        volumeMounts:
        - name: config-volume
          mountPath: /etc/nginx/conf.d
        - name: shared-data
          mountPath: /shared
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
      volumes:
      - name: config-volume
        configMap:
          name: nginx-config
      - name: shared-data
        persistentVolumeClaim:
          claimName: shared-data-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: microservices
  labels:
    app: user-service
spec:
  selector:
    app: user-service
  ports:
  - name: http
    port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Deploy Product Service
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: microservices
  labels:
    app: product-service
    tier: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
        tier: backend
    spec:
      serviceAccountName: microservice-sa
      containers:
      - name: product-service
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        env:
        - name: SERVICE_NAME
          value: "product-service"
        - name: SERVICE_PORT
          value: "80"
        envFrom:
        - configMapRef:
            name: microservice-config
        - secretRef:
            name: service-credentials
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: microservices
  labels:
    app: product-service
spec:
  selector:
    app: product-service
  ports:
  - name: http
    port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Create nginx configuration for services
kubectl create configmap nginx-config \
  --from-literal=default.conf='
server {
    listen 80;
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    location /metrics {
        access_log off;
        return 200 "# Mock metrics endpoint\n";
        add_header Content-Type text/plain;
    }
    location / {
        return 200 "Service running\n";
        add_header Content-Type text/plain;
    }
}' \
  -n microservices --dry-run=client -o yaml | kubectl apply -f -

# Deploy API Gateway
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: microservices
  labels:
    app: api-gateway
    tier: gateway
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
        tier: gateway
    spec:
      serviceAccountName: microservice-sa
      containers:
      - name: api-gateway
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        env:
        - name: USER_SERVICE_URL
          value: "http://user-service.microservices.svc.cluster.local"
        - name: PRODUCT_SERVICE_URL
          value: "http://product-service.microservices.svc.cluster.local"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: microservices
  labels:
    app: api-gateway
spec:
  selector:
    app: api-gateway
  ports:
  - name: http
    port: 80
    targetPort: 80
  type: ClusterIP
EOF

echo "Service Discovery and Load Balancing setup completed successfully!"
