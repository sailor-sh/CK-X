# CKS-002 Kubernetes Security Specialist Lab - Answers

This document contains detailed solutions for all questions in the CKS-002 lab.

## Question 1: RBAC Implementation

Create Role-Based Access Control (RBAC) configuration:

```bash
# Create namespaces
kubectl create namespace dev-team
kubectl create namespace prod-team

# Create ServiceAccount
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dev-user
  namespace: dev-team
EOF

# Create Role for dev-team namespace
cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev-team
  name: dev-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
EOF

# Create RoleBinding
cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-binding
  namespace: dev-team
subjects:
- kind: ServiceAccount
  name: dev-user
  namespace: dev-team
roleRef:
  kind: Role
  name: dev-role
  apiGroup: rbac.authorization.k8s.io
EOF

# Create ClusterRole for limited cluster-wide access
cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: limited-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "namespaces"]
  verbs: ["get", "list"]
EOF

# Create ClusterRoleBinding
cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dev-cluster-binding
subjects:
- kind: ServiceAccount
  name: dev-user
  namespace: dev-team
roleRef:
  kind: ClusterRole
  name: limited-reader
  apiGroup: rbac.authorization.k8s.io
EOF

# Create sample applications in both namespaces
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-app
  namespace: dev-team
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dev-app
  template:
    metadata:
      labels:
        app: dev-app
    spec:
      containers:
      - name: app
        image: nginx:1.20
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prod-app
  namespace: prod-team
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prod-app
  template:
    metadata:
      labels:
        app: prod-app
    spec:
      containers:
      - name: app
        image: nginx:1.20
        ports:
        - containerPort: 80
EOF
```

## Question 2: Network Policies

Implement network segmentation using NetworkPolicies:

```bash
# Create namespace
kubectl create namespace secure-net

# Create default deny-all policy
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: secure-net
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Create policy to allow frontend to backend communication
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: secure-net
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 8080
  - to: {}
    ports:
    - protocol: UDP
      port: 53
EOF

# Create policy to allow backend to receive from frontend
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend
  namespace: secure-net
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  - to: {}
    ports:
    - protocol: UDP
      port: 53
EOF

# Create test pods
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: secure-net
  labels:
    app: frontend
spec:
  containers:
  - name: frontend
    image: nginx:1.20
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: backend
  namespace: secure-net
  labels:
    app: backend
spec:
  containers:
  - name: backend
    image: httpd:2.4
    ports:
    - containerPort: 8080
---
apiVersion: v1
kind: Pod
metadata:
  name: database
  namespace: secure-net
  labels:
    app: database
spec:
  containers:
  - name: database
    image: postgres:13
    ports:
    - containerPort: 5432
    env:
    - name: POSTGRES_PASSWORD
      value: "secretpassword"
EOF
```

## Question 3: Pod Security Standards

Configure Pod Security Standards and contexts:

```bash
# Create namespace with Pod Security Standards
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: secure-pods
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
EOF

# Create ServiceAccount with security context
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secure-sa
  namespace: secure-pods
EOF

# Create pod with secure configuration
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
  namespace: secure-pods
  labels:
    app: secure-app
spec:
  serviceAccountName: secure-sa
  securityContext:
    runAsNonRoot: true
    runAsUser: 1001
    runAsGroup: 3000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx:1.20
    ports:
    - containerPort: 8080
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1001
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE
    volumeMounts:
    - name: cache-volume
      mountPath: /var/cache/nginx
    - name: run-volume
      mountPath: /var/run
  volumes:
  - name: cache-volume
    emptyDir: {}
  - name: run-volume
    emptyDir: {}
EOF
```

## Question 4: Secrets Management and Encryption

Implement secure secrets handling:

```bash
# Create namespace
kubectl create namespace secrets-demo

# Create Secret for database credentials
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: secrets-demo
type: Opaque
data:
  username: YWRtaW4=
  password: MWYyZDFlMmU2N2Rm
EOF

# Create TLS Secret
kubectl create secret tls tls-secret \
  --cert=./tls.crt \
  --key=./tls.key \
  --namespace=secrets-demo \
  --dry-run=client -o yaml | kubectl apply -f -

# Alternative: Create self-signed certificate for demo
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/tls.key -out /tmp/tls.crt \
  -subj "/CN=example.com/O=example.com"

kubectl create secret tls tls-secret \
  --cert=/tmp/tls.crt \
  --key=/tmp/tls.key \
  --namespace=secrets-demo

# Create deployment using secrets
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-secrets
  namespace: secrets-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-with-secrets
  template:
    metadata:
      labels:
        app: app-with-secrets
    spec:
      containers:
      - name: app
        image: nginx:1.20
        ports:
        - containerPort: 443
        envFrom:
        - secretRef:
            name: database-credentials
        volumeMounts:
        - name: tls-volume
          mountPath: /etc/ssl/certs
          readOnly: true
      volumes:
      - name: tls-volume
        secret:
          secretName: tls-secret
EOF
```

## Question 5: Image Security and Scanning

Configure image security policies:

```bash
# Create namespace
kubectl create namespace image-security

# Create deployment with secure image practices
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: image-security
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 2000
      containers:
      - name: app
        image: nginx:1.20.2-alpine
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1001
          capabilities:
            drop:
            - ALL
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        volumeMounts:
        - name: cache-volume
          mountPath: /var/cache/nginx
        - name: run-volume
          mountPath: /var/run
      volumes:
      - name: cache-volume
        emptyDir: {}
      - name: run-volume
        emptyDir: {}
EOF

# Example ImagePolicy (if supported by cluster)
# Note: This requires admission controllers configuration
cat << EOF | kubectl apply -f - || echo "ImagePolicy may not be supported"
apiVersion: config.gatekeeper.sh/v1alpha1
kind: Config
metadata:
  name: config
  namespace: gatekeeper-system
spec:
  match:
    - excludedNamespaces: ["kube-system", "gatekeeper-system"]
      processes: ["*"]
  validation:
    traces:
      - user:
          kind:
            group: "*"
            version: "*"
            kind: "*"
      - kind:
          group: "*"
          version: "*"
          kind: "*"
EOF
```

## Question 6: Admission Controllers and OPA

Configure admission control policies:

```bash
# Create namespace with policy requirements
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: policy-demo
  labels:
    security-level: "high"
    policy-enforcement: "strict"
EOF

# Create compliant deployment
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: compliant-app
  namespace: policy-demo
  labels:
    app: compliant-app
    version: "v1.0"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: compliant-app
  template:
    metadata:
      labels:
        app: compliant-app
        version: "v1.0"
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 2000
      containers:
      - name: app
        image: nginx:1.20.2-alpine
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1001
          capabilities:
            drop:
            - ALL
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        volumeMounts:
        - name: tmp-volume
          mountPath: /tmp
        - name: cache-volume
          mountPath: /var/cache/nginx
      volumes:
      - name: tmp-volume
        emptyDir: {}
      - name: cache-volume
        emptyDir: {}
EOF
```

## Security Verification Commands

```bash
# Check RBAC permissions
kubectl auth can-i --list --as=system:serviceaccount:dev-team:dev-user

# Test network policies
kubectl exec -n secure-net frontend -- curl backend:8080
kubectl exec -n secure-net backend -- curl database:5432

# Check pod security contexts
kubectl get pods -n secure-pods -o jsonpath='{.items[*].spec.securityContext}'

# Verify secrets
kubectl get secrets -n secrets-demo
kubectl describe secret database-credentials -n secrets-demo

# Check image policies
kubectl describe pod -n image-security

# Verify admission control
kubectl get pods -n policy-demo
kubectl describe pods -n policy-demo

# Security audit commands
kubectl get networkpolicies --all-namespaces
kubectl get rolebindings --all-namespaces
kubectl get clusterrolebindings
kubectl get podsecuritypolicies || echo "PSP deprecated in favor of Pod Security Standards"
```
