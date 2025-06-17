#!/bin/bash

# Question 3 Setup: Ingress Controller and TLS
# Setup NGINX Ingress Controller with TLS termination

set -e

echo "Setting up Ingress Controller and TLS..."

# Deploy NGINX Ingress Controller
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: ingress-system
  labels:
    app: nginx-ingress-controller
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-ingress-controller
  template:
    metadata:
      labels:
        app: nginx-ingress-controller
    spec:
      serviceAccount: nginx-ingress-serviceaccount
      containers:
      - name: nginx-ingress-controller
        image: nginx/nginx-ingress:3.4.0
        ports:
        - name: http
          containerPort: 80
        - name: https
          containerPort: 443
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        args:
        - -nginx-configmaps=\$(POD_NAMESPACE)/nginx-configuration
        - -default-server-tls-secret=\$(POD_NAMESPACE)/default-server-secret
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-ingress-serviceaccount
  namespace: ingress-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: nginx-ingress-clusterrole
rules:
- apiGroups: [""]
  resources: ["configmaps", "endpoints", "nodes", "pods", "secrets"]
  verbs: ["list", "watch"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["create", "patch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses/status"]
  verbs: ["update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: nginx-ingress-clusterrole-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: nginx-ingress-clusterrole
subjects:
- kind: ServiceAccount
  name: nginx-ingress-serviceaccount
  namespace: ingress-system
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress-controller-service
  namespace: ingress-system
spec:
  type: NodePort
  ports:
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30080
  - name: https
    port: 443
    targetPort: 443
    nodePort: 30443
  selector:
    app: nginx-ingress-controller
EOF

# Create TLS certificate (self-signed for demo)
kubectl create secret tls microservices-tls \
  --cert=/dev/null \
  --key=/dev/null \
  -n ingress-system --dry-run=client -o yaml | \
  sed 's/null/LS0tLS1CRUdJTi==/' | kubectl apply -f -

# Create default server secret
kubectl create secret tls default-server-secret \
  --cert=/dev/null \
  --key=/dev/null \
  -n ingress-system --dry-run=client -o yaml | \
  sed 's/null/LS0tLS1CRUdJTi==/' | kubectl apply -f -

# Create nginx configuration configmap
kubectl create configmap nginx-configuration \
  --from-literal=use-forwarded-headers=true \
  --from-literal=compute-full-forwarded-for=true \
  --from-literal=use-proxy-protocol=false \
  -n ingress-system --dry-run=client -o yaml | kubectl apply -f -

# Create ingress for microservices
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: microservices-ingress
  namespace: microservices
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - api.microservices.local
    - users.microservices.local
    - products.microservices.local
    secretName: microservices-tls
  rules:
  - host: api.microservices.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 80
  - host: users.microservices.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 80
  - host: products.microservices.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: product-service
            port:
              number: 80
EOF

echo "Ingress Controller and TLS setup completed successfully!"
