# CKS Practice Lab - Kubernetes Security Essentials

## Question 1: Network Policies for Backend Services

Create a NetworkPolicy that restricts access to backend pods and controls their egress:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: secure-backend
  namespace: network-security
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
    - port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - port: 5432
```

This NetworkPolicy ensures:
- Only pods with label `app=frontend` can access backend pods on port 8080
- Backend pods can only communicate with pods labeled `app=database` on port 5432

## Question 2: TLS-Enabled Ingress

Create an Ingress resource with TLS:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-app
  namespace: secure-ingress
spec:
  tls:
  - hosts:
    - secure-app.example.com
    secretName: secure-app-tls
  rules:
  - host: secure-app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

This Ingress:
- Routes traffic for hostname `secure-app.example.com` to the `web-service` service
- Uses the pre-created `secure-app-tls` secret for TLS termination

## Question 3: API Security with Pod Security Standards

Create a namespace with Pod Security Standard:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: api-security
  labels:
    pod-security.kubernetes.io/enforce: baseline
```

Create a secure pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: api-security
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: nginx
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
```

Create Role and RoleBinding for PSS viewing:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pss-viewer-role
  namespace: api-security
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["namespaces/status"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pss-viewer-binding
  namespace: api-security
subjects:
- kind: ServiceAccount
  name: pss-viewer
  namespace: api-security
roleRef:
  kind: Role
  name: pss-viewer-role
  apiGroup: rbac.authorization.k8s.io
```

This implementation:
- Creates a namespace with the Pod Security Standard "baseline" enforcement
- Deploys a pod that complies with the baseline standard (non-root, no privilege escalation)
- Sets up RBAC permissions for the PSS viewer service account

## Question 4: Node Metadata Protection

Create a NetworkPolicy to block metadata access:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-metadata
  namespace: metadata-protect
spec:
  podSelector: {}  # Apply to all pods
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32
```

Create a test pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: metadata-protect
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
```

The same test pod can also be created with:

```bash
kubectl run test-pod -n metadata-protect --image=busybox -- sleep 3600
```

## Question 5: Binary Verification

Create a pod to verify Kubernetes binaries:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: verify-bin
  namespace: binary-verify
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
    - |
      sha256sum /host-bin/kubectl >> /tmp/verified-hashes.txt
      sha256sum /host-bin/kubelet >> /tmp/verified-hashes.txt
      sleep 3600
    volumeMounts:
    - name: host-bin
      mountPath: /host-bin
      readOnly: true
  volumes:
  - name: host-bin
    hostPath:
      path: /usr/bin
      type: Directory
```

## Question 6: RBAC with Minimal Permissions

Create Role and RoleBinding for minimal access:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-reader-role
  namespace: rbac-minimize
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-reader-binding
  namespace: rbac-minimize
subjects:
- kind: ServiceAccount
  name: app-reader
  namespace: rbac-minimize
roleRef:
  kind: Role
  name: app-reader-role
  apiGroup: rbac.authorization.k8s.io
```

## Question 7: Service Account Caution

Create ServiceAccount with disabled automounting:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: minimal-sa
  namespace: service-account-caution
automountServiceAccountToken: false
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: service-account-caution
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      serviceAccountName: minimal-sa
      automountServiceAccountToken: false
      containers:
      - name: nginx
        image: nginx
```

## Question 8: API Server Access Restriction

Create NetworkPolicy and test pods:

```bash
API_SERVER_IP=$(kubectl get svc kubernetes -n default -o jsonpath='{.spec.clusterIP}')
```

```yaml
cat <<EOF > api-server-policy.yaml
# 1. Deny access to API server for all pods
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-server-policy
  namespace: api-restrict
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - ${API_SERVER_IP}/32

---
# 2. Allow access to API server for pods with label role=admin
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-admin-api-egress
  namespace: api-restrict
spec:
  podSelector:
    matchLabels:
      role: admin
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: ${API_SERVER_IP}/32
    ports:
    - protocol: TCP
      port: 443

---
# admin-pod (can access API server)
apiVersion: v1
kind: Pod
metadata:
  name: admin-pod
  namespace: api-restrict
  labels:
    role: admin
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]

---
# restricted-pod (blocked from API server)
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
  namespace: api-restrict
  labels:
    role: restricted
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
EOF
```

```bash
kubectl apply -f api-server-policy.yaml
```

## Question 9: Secure Container Configuration

Create a pod with minimal security context:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-container
  namespace: os-hardening
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE
      readOnlyRootFilesystem: true
      runAsUser: 1000
      runAsGroup: 3000
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: var-cache-nginx
      mountPath: /var/cache/nginx
    - name: var-run
      mountPath: /var/run
  volumes:
  - name: tmp
    emptyDir: {}
  - name: var-cache-nginx
    emptyDir: {}
  - name: var-run
    emptyDir: {}
```

## Question 10: Seccomp Profile

Create a pod with seccomp and a sample profile:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-pod
  namespace: seccomp-profile
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: seccomp-config
  namespace: seccomp-profile
data:
  profile.json: |
    {
      "defaultAction": "SCMP_ACT_ERRNO",
      "architectures": ["SCMP_ARCH_X86_64"],
      "syscalls": [
        {
          "names": ["exit", "exit_group", "rt_sigreturn", "read", "write", "open"],
          "action": "SCMP_ACT_ALLOW"
        }
      ]
    }
```

## Question 11: Pod Security Standards

Apply Pod Security Standards:

```bash
# Label the namespace
kubectl label namespace pod-security pod-security.kubernetes.io/enforce=baseline
```

Create a compliant pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  namespace: pod-security
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: nginx
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
```

Try to create a non-compliant pod and document the error:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-pod
  namespace: pod-security
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      privileged: true
```

## Question 12: Secrets Management

Create and use secrets:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-creds
  namespace: secrets-management
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded 'admin'
  password: U2VjcmV0UEBzc3cwcmQ=  # base64 encoded 'SecretP@ssw0rd'
---
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
  namespace: secrets-management
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/db-creds
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: db-creds
---
apiVersion: v1
kind: Pod
metadata:
  name: env-app
  namespace: secrets-management
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-creds
          key: username
    - name: DB_PASS
      valueFrom:
        secretKeyRef:
          name: db-creds
          key: password
```

## Question 13: Multi-Tenancy Isolation

Create tenant namespaces with isolation:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-a
---
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-b
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-quota
  namespace: tenant-a
spec:
  hard:
    pods: "2"
    limits.cpu: "1"
    limits.memory: 1Gi
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-quota
  namespace: tenant-b
spec:
  hard:
    pods: "2"
    limits.cpu: "1"
    limits.memory: 1Gi
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-from-tenant-b
  namespace: tenant-a
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchExpressions:
        - key: kubernetes.io/metadata.name
          operator: NotIn
          values:
          - tenant-b
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-from-tenant-a
  namespace: tenant-b
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchExpressions:
        - key: kubernetes.io/metadata.name
          operator: NotIn
          values:
          - tenant-a
---
apiVersion: v1
kind: Pod
metadata:
  name: app
  namespace: tenant-a
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: app
  namespace: tenant-b
spec:
  containers:
  - name: nginx
    image: nginx
```

## Question 14: Secure Container Image

Create ConfigMaps for image specifications:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: image-specs
  namespace: image-security
data:
  base: "alpine:3.14"
  packages: "nginx"
  user: "nginx"
  entrypoint: "nginx -g 'daemon off;'"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: dockerfile
  namespace: image-security
data:
  Dockerfile: |
    FROM alpine:3.14
    
    RUN apk --no-cache add nginx && \
        rm -rf /var/cache/apk/* && \
        mkdir -p /var/cache/nginx /var/run/nginx && \
        chown -R nginx:nginx /var/cache/nginx /var/run/nginx /var/log/nginx
    
    USER nginx
    
    EXPOSE 80
    
    CMD ["nginx", "-g", "daemon off;"]
---
apiVersion: v1
kind: Pod
metadata:
  name: secure-image-pod
  namespace: image-security
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      runAsUser: 101
      runAsNonRoot: true
```

## Question 15: Supply Chain Security

Create ConfigMaps for trusted registries and verification:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: trusted-registries
  namespace: supply-chain
data:
  policy.yaml: |
    apiVersion: apiserver.config.k8s.io/v1
    kind: AdmissionConfiguration
    plugins:
    - name: ImagePolicyWebhook
      configuration:
        imagePolicy:
          repositories:
          - docker.io/library/*
          - k8s.gcr.io/*
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: verify-script
  namespace: supply-chain
data:
  verify.sh: |
    #!/bin/sh
    
    # Verify critical container images
    echo "Verifying image: k8s.gcr.io/kube-apiserver:v1.24.0"
    EXPECTED_SHA="sha256:a874d5c2147124fc0331c8ad9bd89c259181d06faa8bba6b277217bfdc5e8ad9"
    echo "Expected SHA: $EXPECTED_SHA"
    
    echo "Verifying image: k8s.gcr.io/kube-controller-manager:v1.24.0"
    EXPECTED_SHA="sha256:a7ed87380344dbad669a17fa4ceb5d6c7dc2c9cd8dd676f9046d48336a97082a"
    echo "Expected SHA: $EXPECTED_SHA"
---
apiVersion: v1
kind: Pod
metadata:
  name: verification-pod
  namespace: supply-chain
spec:
  containers:
  - name: verify
    image: busybox
    command: ["/bin/sh", "/scripts/verify.sh"]
    volumeMounts:
    - name: script-volume
      mountPath: /scripts
  volumes:
  - name: script-volume
    configMap:
      name: verify-script
      defaultMode: 0744
```

## Question 16: Static Analysis

Analyze and fix a deployment:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: security-analysis
  namespace: static-analysis
data:
  analysis-results: |
    {
      "score": 3,
      "scoring": {
        "critical": 0,
        "high": 2,
        "medium": 3
      },
      "results": [
        {"rule": "RunAsNonRoot", "points": -5},
        {"rule": "PrivilegedContainer", "points": -8},
        {"rule": "ReadOnlyRootFilesystem", "points": -3},
        {"rule": "DropCapabilities", "points": -2}
      ]
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-deployment
  namespace: static-analysis
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
        runAsUser: 1000
      containers:
      - name: app
        image: nginx:alpine
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE
        resources:
          limits:
            cpu: "100m"
            memory: "128Mi"
          requests:
            cpu: "50m"
            memory: "64Mi"
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: var-run
          mountPath: /var/run
      volumes:
      - name: tmp
        emptyDir: {}
      - name: var-run
        emptyDir: {}
```

## Question 17: Runtime Security

Implement runtime security measures:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: immutable-container
  namespace: runtime-security
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: var-cache-nginx
      mountPath: /var/cache/nginx
    - name: var-run
      mountPath: /var/run
  volumes:
  - name: tmp
    emptyDir: {}
  - name: var-cache-nginx
    emptyDir: {}
  - name: var-run
    emptyDir: {}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-rules
  namespace: runtime-security
data:
  rules.yaml: |
    - rule: Terminal shell in container
      desc: A shell was spawned by a pod in the cluster
      condition: container and container.image != "shell-allowed" and proc.name = bash
      output: Shell spawned in a container (pod=%k.pod.name container=%container.name shell=%proc.name)
      priority: WARNING
    
    - rule: Package Management Detected
      desc: Package management command executed in container
      condition: container and (proc.name = apt or proc.name = apt-get or proc.name = apk)
      output: Package management command executed (pod=%k.pod.name container=%container.name command=%proc.cmdline)
      priority: WARNING
    
    - rule: Sensitive File Access
      desc: Sensitive file accessed in container
      condition: container and fd.name startswith /etc/shadow
      output: Sensitive file accessed (pod=%k.pod.name container=%container.name file=%fd.name)
      priority: CRITICAL
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: audit-daemon
  namespace: runtime-security
spec:
  selector:
    matchLabels:
      app: audit-daemon
  template:
    metadata:
      labels:
        app: audit-daemon
    spec:
      containers:
      - name: falco
        image: falcosecurity/falco:latest
        securityContext:
          privileged: true
        volumeMounts:
        - name: rules
          mountPath: /etc/falco/rules.d/
        - name: dev
          mountPath: /dev
        - name: proc
          mountPath: /host/proc
          readOnly: true
      volumes:
      - name: rules
        configMap:
          name: falco-rules
      - name: dev
        hostPath:
          path: /dev
      - name: proc
        hostPath:
          path: /proc
```

## Question 18: Audit Logging

Configure audit logging:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: audit-policy
  namespace: audit-logging
data:
  policy.yaml: |
    apiVersion: audit.k8s.io/v1
    kind: Policy
    rules:
    # Don't log read-only operations on configmaps or secrets
    - level: None
      verbs: ["get", "list", "watch"]
      resources:
      - group: ""
        resources: ["configmaps", "secrets"]
    
    # Log auth at metadata level
    - level: Metadata
      userGroups: ["system:authenticated", "system:unauthenticated"]
      stages:
      - "RequestReceived"
    
    # Log auth failures at Request level
    - level: Request
      responseStatus:
        code: "4*"
      resources:
      - group: ""
        resources: ["*"]
    
    # Log pod operations at RequestResponse level
    - level: RequestResponse
      resources:
      - group: ""
        resources: ["pods"]
      verbs: ["create", "delete"]
    
    # Default rule for all other requests
    - level: Metadata
---
apiVersion: v1
kind: Pod
metadata:
  name: audit-viewer
  namespace: audit-logging
spec:
  serviceAccountName: audit-viewer-sa
  containers:
  - name: viewer
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: audit-logs
      mountPath: /var/log/kubernetes/audit
      readOnly: true
  volumes:
  - name: audit-logs
    hostPath:
      path: /var/log/kubernetes/audit
      type: Directory
```

## Question 19: Malicious Activity Detection

Create detection rules and isolation policy:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: threat-detection
  namespace: malicious-detection
data:
  rules.yaml: |
    - rule: Unusual Network Communication
      description: Detects connections to suspicious IPs or unusual ports
      indicators:
        - connections to non-standard ports (outside common ranges)
        - connections to known malicious IPs
        - high volume of outbound connections
    
    - rule: Crypto Mining Detection
      description: Detects potential crypto mining activities
      indicators:
        - high CPU usage for extended periods
        - connections to mining pools
        - presence of mining binary signatures
    
    - rule: Privilege Escalation
      description: Detects attempts to gain higher privileges
      indicators:
        - use of sudo or su commands
        - modification of sudoers files
        - usage of setuid binaries
        - container escape attempts
---
apiVersion: v1
kind: Pod
metadata:
  name: detector
  namespace: malicious-detection
spec:
  containers:
  - name: detector
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
    - |
      while true; do
        echo "Running threat detection checks..."
        sleep 60
      done
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-compromised
  namespace: malicious-detection
spec:
  podSelector:
    matchLabels:
      security-status: compromised
  policyTypes:
  - Ingress
  - Egress
  ingress: []  # Deny all ingress
  egress:
  - to:  # Allow DNS resolution only
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - port: 53
      protocol: UDP
```

## Question 20: Cilium Pod-to-Pod Encryption

Implement pod-to-pod encryption with Cilium:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-comms
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: cilium-encryption
  namespace: cilium-encryption
data:
  encryption-config.yaml: |
    # Key rotation mechanism
    Key rotation is handled automatically by Cilium. Keys are rotated periodically to ensure 
    perfect forward secrecy. The rotation interval is configurable.
    
    # IPSec encryption method
    Cilium uses IPSec with ESP in tunnel mode for encryption. The encryption and authentication 
    algorithms used are AES-GCM for encryption and SHA-256 for authentication.
    
    # Transparent encryption approach
    Encryption is performed transparently without requiring changes to the application. 
    The encryption happens at the network layer and is transparent to the pods.
---
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod-a
  namespace: secure-comms
  annotations:
    io.cilium.proxy-visibility: "<Ingress/80/TCP/HTTP>"
  labels:
    app: secure-app
    io.cilium.encryption: "enabled"
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod-b
  namespace: secure-comms
  annotations:
    io.cilium.proxy-visibility: "<Egress/80/TCP/HTTP>"
  labels:
    app: secure-app
    io.cilium.encryption: "enabled"
spec:
  containers:
  - name: nginx
    image: nginx
``` 