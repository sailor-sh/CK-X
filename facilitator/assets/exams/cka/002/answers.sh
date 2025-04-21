#!/bin/bash

# answers.md convetred to answers.sh for quick testing 
echo "Implementing Question 1: Dynamic PVC and Pod"
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: storage-task
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: data-pod
  namespace: storage-task
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /usr/share/nginx/html
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-pvc
EOF

echo "Implementing Question 2: Storage Class Configuration"
cat <<'EOF' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-local
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
EOF

kubectl patch storageclass default-test -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'
kubectl patch storageclass local-path -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'

echo "Implementing Question 3: Manual Storage Configuration"
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: manual-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - k3d-cluster-agent-0
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: manual-pvc
  namespace: manual-storage
spec:
  storageClassName: ""
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: manual-pod
  namespace: manual-storage
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: manual-pvc
EOF

echo "Implementing Question 4: Deployment with HPA"
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scaling-app
  namespace: scaling
spec:
  replicas: 2
  selector:
    matchLabels:
      app: scaling-app
  template:
    metadata:
      labels:
        app: scaling-app
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
---
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: scaling-app
  namespace: scaling
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: scaling-app
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70
EOF

echo "Implementing Question 5: Node Affinity Configuration"
kubectl label node k3d-cluster-agent-1 disk=ssd

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-scheduling
  namespace: scheduling
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app-scheduling
  template:
    metadata:
      labels:
        app: app-scheduling
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: disk
                operator: In
                values:
                - ssd
      containers:
      - name: nginx
        image: nginx
EOF

echo "Implementing Question 6: Pod Security Policy"
kubectl label namespace security pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/enforce-version=latest

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: security
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      runAsUser: 1000
      capabilities:
        drop:
          - ALL
  volumes:
  - name: html
    emptyDir: {}
EOF

echo "Implementing Question 7: Node Taints and Tolerations"
kubectl taint node k3d-cluster-agent-1 special-workload=true:NoSchedule

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: toleration-deploy
  namespace: scheduling
spec:
  replicas: 2
  selector:
    matchLabels:
      app: toleration-deploy
  template:
    metadata:
      labels:
        app: toleration-deploy
    spec:
      tolerations:
      - key: "special-workload"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
      containers:
      - name: nginx
        image: nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: normal-deploy
  namespace: scheduling
spec:
  replicas: 2
  selector:
    matchLabels:
      app: normal-deploy
  template:
    metadata:
      labels:
        app: normal-deploy
    spec:
      containers:
      - name: nginx
        image: nginx
EOF

echo "Implementing Question 8: StatefulSet and Headless Service"

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: stateful
spec:
  clusterIP: None
  selector:
    app: web
  ports:
  - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
  namespace: stateful
spec:
  serviceName: web-svc
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: cold
      resources:
        requests:
          storage: 1Gi
EOF

echo "Implementing Question 9: DNS Configuration and Debugging"
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: dns-debug
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: dns-debug
spec:
  selector:
    app: web-app
  ports:
  - port: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: dns-test
  namespace: dns-debug
spec:
  containers:
  - name: busybox
    image: busybox
    command: 
    - sh
    - -c
    - "wget -qO- http://web-svc && wget -qO- http://web-svc.dns-debug.svc.cluster.local && sleep 36000"
  dnsConfig:
    searches:
    - dns-debug.svc.cluster.local
    - svc.cluster.local
    - cluster.local
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: dns-config
  namespace: dns-debug
data:
  search-domains: |
    search dns-debug.svc.cluster.local svc.cluster.local cluster.local
EOF

echo "Implementing Question 10: Set up basic DNS service discovery"
echo "Implementing solution for Question 10"
kubectl create namespace dns-config

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dns-app
  namespace: dns-config
spec:
  replicas: 2
  selector:
    matchLabels:
      app: dns-app
  template:
    metadata:
      labels:
        app: dns-app
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
# Create the service
apiVersion: v1
kind: Service
metadata:
  name: dns-svc
  namespace: dns-config
spec:
  selector:
    app: dns-app
  ports:
  - port: 80
    targetPort: 80
---
# Create the DNS tester pod
apiVersion: v1
kind: Pod
metadata:
  name: dns-tester
  namespace: dns-config
spec:
  containers:
  - name: dns-tester
    image: infoblox/dnstools
    command:
    - sh
    - -c
    - |
      nslookup dns-svc > /tmp/dns-test.txt
      nslookup dns-svc.dns-config.svc.cluster.local >> /tmp/dns-test.txt
      sleep 3600
EOF

echo "Implementing Question 11: Helm Chart Deployment"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install web-release bitnami/nginx \
  --namespace helm-test \
  --set service.type=NodePort \
  --set replicaCount=2

echo "Implementing Question 12: Kustomize Configuration"
mkdir -p /tmp/exam/kustomize/base
mkdir -p /tmp/exam/kustomize/overlays/production

cat <<'EOF' > /tmp/exam/kustomize/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: nginx-index
          mountPath: /usr/share/nginx/html/
      volumes:
      - name: nginx-index
        configMap:
          name: nginx-config
EOF

cat <<'EOF' > /tmp/exam/kustomize/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
EOF

cat <<'EOF' > /tmp/exam/kustomize/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: kustomize
bases:
- ../../base
patches:
- patch: |
    - op: replace
      path: /spec/replicas
      value: 3
  target:
    kind: Deployment
    name: nginx
commonLabels:
  environment: production
configMapGenerator:
- name: nginx-config
  literals:
  - index.html=Welcome to Production
EOF

kubectl create namespace kustomize
kubectl apply -k /tmp/exam/kustomize/overlays/production/

echo "Implementing Question 13: Gateway API Configuration"
cat <<'EOF' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: main-gateway
  namespace: gateway
spec:
  gatewayClassName: standard
  listeners:
  - name: http
    port: 80
    protocol: HTTP
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: app-routes
  namespace: gateway
spec:
  parentRefs:
  - name: main-gateway
  rules:
  - matches:
    - path:
        value: /app1
    backendRefs:
    - name: app1-svc
      port: 8080
  - matches:
    - path:
        value: /app2
    backendRefs:
    - name: app2-svc
      port: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
  namespace: gateway
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: nginx
        image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: app1-svc
  namespace: gateway
spec:
  selector:
    app: app1
  ports:
  - port: 8080
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
  namespace: gateway
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: nginx
        image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: app2-svc
  namespace: gateway
spec:
  selector:
    app: app2
  ports:
  - port: 8080
    targetPort: 80
EOF

echo "Implementing Question 14: Resource Limits and Quotas"
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: limits
spec:
  limits:
  - type: Container
    default:
      cpu: 200m
      memory: 256Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    max:
      cpu: 500m
      memory: 512Mi
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: limits
spec:
  hard:
    cpu: "2"
    memory: 2Gi
    pods: "5"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-limits
  namespace: limits
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-limits
  template:
    metadata:
      labels:
        app: test-limits
    spec:
      containers:
      - name: nginx
        image: nginx
EOF

echo "Implementing Question 15: Horizontal Pod Autoscaling"
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-consumer
  namespace: monitoring
spec:
  replicas: 3
  selector:
    matchLabels:
      app: resource-consumer
  template:
    metadata:
      labels:
        app: resource-consumer
    spec:
      containers:
      - name: resource-consumer
        image: gcr.io/kubernetes-e2e-test-images/resource-consumer:1.5
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: resource-consumer
  namespace: monitoring
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: resource-consumer
  minReplicas: 3
  maxReplicas: 6
  targetCPUUtilizationPercentage: 50
EOF

echo "Implementing Question 16: RBAC Configuration"
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-admin
  namespace: cluster-admin
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-admin
  namespace: cluster-admin
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["list", "get", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["list", "get", "watch", "update"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["create", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-admin
  namespace: cluster-admin
subjects:
- kind: ServiceAccount
  name: app-admin
  namespace: cluster-admin
roleRef:
  kind: Role
  name: app-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: Pod
metadata:
  name: admin-pod
  namespace: cluster-admin
spec:
  serviceAccountName: app-admin
  containers:
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["sleep", "3600"]
    volumeMounts:
    - name: token
      mountPath: /var/run/secrets/kubernetes.io/serviceaccount
  volumes:
  - name: token
    projected:
      sources:
      - serviceAccountToken:
          expirationSeconds: 3600
          audience: kubernetes.default.svc
EOF

echo "Implementing Question 17: Network Policies"
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: network
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: network
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: nginx
        image: nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db
  namespace: network
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: postgres
        image: postgres
        env:
        - name: POSTGRES_HOST_AUTH_METHOD
          value: trust
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-policy
  namespace: network
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: api
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-policy
  namespace: network
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Egress
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: db
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: network
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api
EOF

echo "Implementing Question 18: Rolling Updates"
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
  namespace: upgrade
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: app-v1
  template:
    metadata:
      labels:
        app: app-v1
    spec:
      containers:
      - name: nginx
        image: nginx:1.19
EOF

kubectl set image deployment/app-v1 nginx=nginx:1.20 -n upgrade --record
kubectl rollout history deployment app-v1 -n upgrade > /tmp/exam/rollout-history.txt
kubectl rollout undo deployment/app-v1 -n upgrade

echo "Implementing Question 19: Pod Priority and Anti-affinity"
cat <<'EOF' | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 100
---
apiVersion: v1
kind: Pod
metadata:
  name: high-priority
  namespace: scheduling
  labels:
    priority: high  
spec:
  priorityClassName: high-priority
  containers:
  - name: nginx
    image: nginx
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: priority
            operator: In
            values:
            - high
            - low
        topologyKey: kubernetes.io/hostname
---
apiVersion: v1
kind: Pod
metadata:
  name: low-priority
  namespace: scheduling
  labels:
    priority: low  
spec:
  priorityClassName: low-priority
  containers:
  - name: nginx
    image: nginx
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: priority
            operator: In
            values:
            - high
            - low
        topologyKey: kubernetes.io/hostname
EOF

echo "Implementing Question 20: Troubleshooting Application"
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: failing-app
  namespace: troubleshoot
spec:
  replicas: 3
  selector:
    matchLabels:
      app: failing-app
  template:
    metadata:
      labels:
        app: failing-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:
          limits:
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 10
EOF

echo "All solutions have been implemented successfully!" 