#!/bin/bash

# Question 5 Setup: CI/CD Pipeline Infrastructure
# Setup GitOps and CI/CD components

set -e

echo "Setting up CI/CD Pipeline Infrastructure..."

# Deploy ArgoCD for GitOps
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-server
  namespace: cicd
  labels:
    app: argocd-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: argocd-server
  template:
    metadata:
      labels:
        app: argocd-server
    spec:
      serviceAccount: argocd-server
      containers:
      - name: argocd-server
        image: argoproj/argocd:v2.8.0
        ports:
        - containerPort: 8080
        - containerPort: 8083
        command:
        - argocd-server
        - --insecure
        - --staticassets
        - /shared/app
        env:
        - name: ARGOCD_SERVER_INSECURE
          value: "true"
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
  name: argocd-server
  namespace: cicd
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argocd-server
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
- nonResourceURLs: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argocd-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: argocd-server
subjects:
- kind: ServiceAccount
  name: argocd-server
  namespace: cicd
---
apiVersion: v1
kind: Service
metadata:
  name: argocd-server
  namespace: cicd
  labels:
    app: argocd-server
spec:
  type: NodePort
  ports:
  - name: http
    port: 80
    targetPort: 8080
    nodePort: 30800
  - name: grpc
    port: 443
    targetPort: 8083
    nodePort: 30443
  selector:
    app: argocd-server
EOF

# Deploy Jenkins for CI
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: cicd
  labels:
    app: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      serviceAccount: jenkins
      containers:
      - name: jenkins
        image: jenkins/jenkins:2.414.1-lts
        ports:
        - containerPort: 8080
        - containerPort: 50000
        env:
        - name: JAVA_OPTS
          value: "-Djenkins.install.runSetupWizard=false"
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
      volumes:
      - name: jenkins-home
        emptyDir: {}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: cicd
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: jenkins
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: jenkins
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: cicd
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins
  namespace: cicd
  labels:
    app: jenkins
spec:
  type: NodePort
  ports:
  - name: http
    port: 8080
    targetPort: 8080
    nodePort: 30808
  - name: jnlp
    port: 50000
    targetPort: 50000
  selector:
    app: jenkins
EOF

# Create pipeline secret for Git access
kubectl create secret generic git-credentials \
  --from-literal=username=git-user \
  --from-literal=password=git-password \
  --from-literal=token=github-token-placeholder \
  -n cicd --dry-run=client -o yaml | kubectl apply -f -

# Create Docker registry secret
kubectl create secret docker-registry docker-registry-secret \
  --docker-server=docker.io \
  --docker-username=docker-user \
  --docker-password=docker-password \
  --docker-email=docker@example.com \
  -n cicd --dry-run=client -o yaml | kubectl apply -f -

# Create ConfigMap for pipeline configurations
kubectl create configmap pipeline-config \
  --from-literal=registry_url=docker.io \
  --from-literal=git_repo_url=https://github.com/example/microservices.git \
  --from-literal=deployment_namespace=microservices \
  --from-literal=image_tag_strategy=commit-sha \
  -n cicd --dry-run=client -o yaml | kubectl apply -f -

# Create ArgoCD Application for microservices
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: microservices-app
  namespace: cicd
spec:
  project: default
  source:
    repoURL: https://github.com/example/microservices-config
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: microservices
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

echo "CI/CD Pipeline Infrastructure setup completed successfully!"
