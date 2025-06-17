# Microservices-001 Architecture Foundation Lab - Answers

This document contains detailed solutions for all questions in the Microservices-001 lab.

## Question 1: Microservices Architecture Foundation

Set up the foundational infrastructure for a microservices platform:

```bash
# Create dedicated namespaces
kubectl create namespace microservices
kubectl create namespace monitoring
kubectl create namespace ingress-system
kubectl create namespace cicd

# Label namespaces for organization
kubectl label namespace microservices tier=application
kubectl label namespace monitoring tier=infrastructure
kubectl label namespace ingress-system tier=networking
kubectl label namespace cicd tier=pipeline

# Create API Gateway deployment
cat << EOF | kubectl apply -f -
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
      containers:
      - name: gateway
        image: nginx:1.20
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway-service
  namespace: microservices
spec:
  selector:
    app: api-gateway
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF

# Create User Service
cat << EOF | kubectl apply -f -
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
      containers:
      - name: user-service
        image: httpd:2.4
        ports:
        - containerPort: 80
        env:
        - name: SERVICE_NAME
          value: "user-service"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: microservices
spec:
  selector:
    app: user-service
  ports:
  - port: 8080
    targetPort: 80
  type: ClusterIP
EOF

# Create Order Service
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: microservices
  labels:
    app: order-service
    tier: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
        tier: backend
    spec:
      containers:
      - name: order-service
        image: httpd:2.4
        ports:
        - containerPort: 80
        env:
        - name: SERVICE_NAME
          value: "order-service"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: microservices
spec:
  selector:
    app: order-service
  ports:
  - port: 8080
    targetPort: 80
  type: ClusterIP
EOF

# Create Redis for caching
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: microservices
  labels:
    app: redis
    tier: cache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
        tier: cache
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: microservices
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
  type: ClusterIP
EOF

# Create NetworkPolicy for microservices communication
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: microservices-network-policy
  namespace: microservices
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-system
    - podSelector: {}
  egress:
  - to:
    - podSelector: {}
  - to:
    - namespaceSelector:
        matchLabels:
          name: monitoring
  - to: {}
    ports:
    - protocol: UDP
      port: 53
EOF
```

## Question 2: Service Discovery and Load Balancing

Implement service discovery with Consul and load balancing with HAProxy:

```bash
# Create Consul for service discovery
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consul
  namespace: microservices
  labels:
    app: consul
    component: service-discovery
spec:
  replicas: 1
  selector:
    matchLabels:
      app: consul
  template:
    metadata:
      labels:
        app: consul
        component: service-discovery
    spec:
      containers:
      - name: consul
        image: consul:1.15
        ports:
        - containerPort: 8500
          name: ui
        - containerPort: 8600
          name: dns
        command:
        - consul
        - agent
        - -server
        - -bootstrap-expect=1
        - -ui
        - -bind=0.0.0.0
        - -client=0.0.0.0
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: consul-service
  namespace: microservices
spec:
  selector:
    app: consul
  ports:
  - port: 8500
    targetPort: 8500
    name: ui
  - port: 8600
    targetPort: 8600
    name: dns
  type: ClusterIP
EOF

# Create HAProxy ConfigMap
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: haproxy-config
  namespace: microservices
data:
  haproxy.cfg: |
    global
        daemon
        maxconn 256

    defaults
        mode http
        timeout connect 5000ms
        timeout client 50000ms
        timeout server 50000ms

    frontend http_front
        bind *:80
        default_backend http_back

    backend http_back
        balance roundrobin
        server backend1 backend-service-1:80 check
        server backend2 backend-service-2:80 check
        server backend3 backend-service-3:80 check
EOF

# Create HAProxy deployment
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: haproxy
  namespace: microservices
  labels:
    app: haproxy
    component: load-balancer
spec:
  replicas: 2
  selector:
    matchLabels:
      app: haproxy
  template:
    metadata:
      labels:
        app: haproxy
        component: load-balancer
    spec:
      containers:
      - name: haproxy
        image: haproxy:2.8
        ports:
        - containerPort: 80
        volumeMounts:
        - name: config
          mountPath: /usr/local/etc/haproxy
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
      volumes:
      - name: config
        configMap:
          name: haproxy-config
---
apiVersion: v1
kind: Service
metadata:
  name: haproxy-service
  namespace: microservices
spec:
  selector:
    app: haproxy
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Create backend services for load balancing
for i in {1..3}; do
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-service-$i
  namespace: microservices
  labels:
    app: backend-service-$i
    component: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend-service-$i
  template:
    metadata:
      labels:
        app: backend-service-$i
        component: backend
    spec:
      containers:
      - name: backend
        image: httpd:2.4
        ports:
        - containerPort: 80
        env:
        - name: INSTANCE_ID
          value: "backend-$i"
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service-$i
  namespace: microservices
spec:
  selector:
    app: backend-service-$i
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
done

# Create load balancer service
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: load-balancer
  namespace: microservices
spec:
  selector:
    app: haproxy
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF
```

## Question 3: Distributed Configuration Management

Set up centralized configuration with etcd and config management:

```bash
# Create etcd for configuration storage
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: etcd
  namespace: microservices
  labels:
    app: etcd
    component: config-store
spec:
  replicas: 1
  selector:
    matchLabels:
      app: etcd
  template:
    metadata:
      labels:
        app: etcd
        component: config-store
    spec:
      containers:
      - name: etcd
        image: quay.io/coreos/etcd:v3.5.9
        ports:
        - containerPort: 2379
        - containerPort: 2380
        env:
        - name: ETCD_NAME
          value: "etcd0"
        - name: ETCD_INITIAL_ADVERTISE_PEER_URLS
          value: "http://etcd-service:2380"
        - name: ETCD_LISTEN_PEER_URLS
          value: "http://0.0.0.0:2380"
        - name: ETCD_LISTEN_CLIENT_URLS
          value: "http://0.0.0.0:2379"
        - name: ETCD_ADVERTISE_CLIENT_URLS
          value: "http://etcd-service:2379"
        - name: ETCD_INITIAL_CLUSTER
          value: "etcd0=http://etcd-service:2380"
        - name: ETCD_INITIAL_CLUSTER_STATE
          value: "new"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: etcd-service
  namespace: microservices
spec:
  selector:
    app: etcd
  ports:
  - port: 2379
    targetPort: 2379
    name: client
  - port: 2380
    targetPort: 2380
    name: peer
  type: ClusterIP
EOF

# Create config manager service
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-manager
  namespace: microservices
  labels:
    app: config-manager
    component: config-management
spec:
  replicas: 1
  selector:
    matchLabels:
      app: config-manager
  template:
    metadata:
      labels:
        app: config-manager
        component: config-management
    spec:
      containers:
      - name: config-manager
        image: nginx:1.20
        ports:
        - containerPort: 80
        env:
        - name: ETCD_ENDPOINT
          value: "etcd-service:2379"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: config-manager-service
  namespace: microservices
spec:
  selector:
    app: config-manager
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Create ConfigMaps for different environments
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-prod
  namespace: microservices
data:
  database_url: "postgres://prod-db:5432/myapp"
  cache_ttl: "3600"
  log_level: "INFO"
  max_connections: "100"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-dev
  namespace: microservices
data:
  database_url: "postgres://dev-db:5432/myapp"
  cache_ttl: "300"
  log_level: "DEBUG"
  max_connections: "10"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: database-config
  namespace: microservices
data:
  max_connections: "200"
  shared_buffers: "256MB"
  effective_cache_size: "1GB"
EOF

# Create Secrets for sensitive configuration
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: microservices
type: Opaque
data:
  username: cG9zdGdyZXM=
  password: c2VjcmV0cGFzc3dvcmQ=
---
apiVersion: v1
kind: Secret
metadata:
  name: api-keys
  namespace: microservices
type: Opaque
data:
  stripe_key: c2tfbGl2ZV9hYmNkZWZnaGlqa2w=
  sendgrid_key: U0cuYWJjZGVmZ2hpams=
---
apiVersion: v1
kind: Secret
metadata:
  name: jwt-secret
  namespace: microservices
type: Opaque
data:
  secret: bXlzdXBlcnNlY3JldGp3dGtleQ==
EOF

# Create microservices using the configuration
for service in user-service order-service payment-service; do
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $service
  namespace: microservices
  labels:
    app: $service
    component: microservice
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $service
  template:
    metadata:
      labels:
        app: $service
        component: microservice
    spec:
      containers:
      - name: $service
        image: httpd:2.4
        ports:
        - containerPort: 80
        envFrom:
        - configMapRef:
            name: app-config-prod
        - secretRef:
            name: database-credentials
        env:
        - name: SERVICE_NAME
          value: "$service"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
EOF
done
```

## Question 4: Observability and Monitoring Stack

Deploy comprehensive monitoring with Prometheus, Grafana, and logging:

```bash
# Create Prometheus deployment
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
    - job_name: 'kubernetes-services'
      kubernetes_sd_configs:
      - role: service
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
  labels:
    app: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:v2.45.0
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
        - name: data
          mountPath: /prometheus
        args:
        - --config.file=/etc/prometheus/prometheus.yml
        - --storage.tsdb.path=/prometheus
        - --web.console.libraries=/etc/prometheus/console_libraries
        - --web.console.templates=/etc/prometheus/consoles
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
      volumes:
      - name: config
        configMap:
          name: prometheus-config
      - name: data
        persistentVolumeClaim:
          claimName: prometheus-data
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
  type: ClusterIP
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-data
  namespace: monitoring
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF

# Create Grafana deployment
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-config
  namespace: monitoring
data:
  grafana.ini: |
    [server]
    http_port = 3000
    [security]
    admin_user = admin
    admin_password = admin123
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
  labels:
    app: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:10.0.0
        ports:
        - containerPort: 3000
        volumeMounts:
        - name: config
          mountPath: /etc/grafana
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
      volumes:
      - name: config
        configMap:
          name: grafana-config
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  namespace: monitoring
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: LoadBalancer
EOF

# Create Jaeger for distributed tracing
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
  namespace: monitoring
  labels:
    app: jaeger
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:1.47
        ports:
        - containerPort: 16686
        - containerPort: 14268
        env:
        - name: COLLECTOR_ZIPKIN_HTTP_PORT
          value: "9411"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: jaeger-service
  namespace: monitoring
spec:
  selector:
    app: jaeger
  ports:
  - port: 16686
    targetPort: 16686
    name: ui
  - port: 14268
    targetPort: 14268
    name: collector
  type: LoadBalancer
EOF

# Create Elasticsearch for log storage
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
  namespace: monitoring
  labels:
    app: elasticsearch
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: elasticsearch:7.17.10
        ports:
        - containerPort: 9200
        env:
        - name: discovery.type
          value: "single-node"
        - name: ES_JAVA_OPTS
          value: "-Xms512m -Xmx512m"
        resources:
          requests:
            cpu: 200m
            memory: 512Mi
          limits:
            cpu: 500m
            memory: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch-service
  namespace: monitoring
spec:
  selector:
    app: elasticsearch
  ports:
  - port: 9200
    targetPort: 9200
  type: ClusterIP
EOF

# Create Fluentd DaemonSet for log collection
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: monitoring
  labels:
    app: fluentd
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      serviceAccountName: fluentd
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-elasticsearch
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch-service"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluentd
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluentd
rules:
- apiGroups: [""]
  resources: ["pods", "namespaces"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fluentd
roleRef:
  kind: ClusterRole
  name: fluentd
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: fluentd
  namespace: monitoring
EOF

# Create ServiceMonitor for Prometheus (if using Prometheus Operator)
cat << EOF | kubectl apply -f - || echo "ServiceMonitor requires Prometheus Operator"
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: microservices-monitor
  namespace: monitoring
spec:
  selector:
    matchLabels:
      tier: backend
  endpoints:
  - port: http
    interval: 30s
    path: /metrics
EOF
```

## Question 5: API Gateway and Traffic Management

Configure advanced traffic management with NGINX Ingress and Istio:

```bash
# Create NGINX Ingress Controller
cat << EOF | kubectl apply -f -
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
      serviceAccountName: nginx-ingress
      containers:
      - name: nginx-ingress-controller
        image: nginx/nginx-ingress:3.2.0
        ports:
        - containerPort: 80
        - containerPort: 443
        - containerPort: 8080
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
        - -nginx-configmaps=$(POD_NAMESPACE)/nginx-configuration
        - -default-backend-service=$(POD_NAMESPACE)/default-http-backend
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-ingress
  namespace: ingress-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: nginx-ingress
rules:
- apiGroups: [""]
  resources: ["services", "endpoints"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch", "update", "create"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses", "ingressclasses"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses/status"]
  verbs: ["update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: nginx-ingress
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: nginx-ingress
subjects:
- kind: ServiceAccount
  name: nginx-ingress
  namespace: ingress-system
EOF

# Create NGINX configuration
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-configuration
  namespace: ingress-system
data:
  rate-limit: "100"
  rate-limit-window: "1m"
  ssl-redirect: "false"
  server-tokens: "false"
EOF

# Create TLS certificate (self-signed for demo)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/tls.key -out /tmp/tls.crt \
  -subj "/CN=api.example.com/O=example"

kubectl create secret tls api-tls-secret \
  --cert=/tmp/tls.crt \
  --key=/tmp/tls.key \
  --namespace=microservices

# Create Ingress resources
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  namespace: microservices
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls-secret
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 8080
      - path: /orders
        pathType: Prefix
        backend:
          service:
            name: order-service
            port:
              number: 8080
      - path: /payments
        pathType: Prefix
        backend:
          service:
            name: payment-service
            port:
              number: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  namespace: microservices
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-gateway-service
            port:
              number: 80
EOF

# Create Istio Gateway and VirtualService (if Istio is installed)
cat << EOF | kubectl apply -f - || echo "Istio not installed, skipping Istio resources"
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: api-gateway
  namespace: microservices
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - api.example.com
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: api-tls-secret
    hosts:
    - api.example.com
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-routes
  namespace: microservices
spec:
  hosts:
  - api.example.com
  gateways:
  - api-gateway
  http:
  - match:
    - uri:
        prefix: /users
    route:
    - destination:
        host: user-service
        port:
          number: 8080
      weight: 100
  - match:
    - uri:
        prefix: /orders
    route:
    - destination:
        host: order-service
        port:
          number: 8080
      weight: 100
  - match:
    - uri:
        prefix: /payments
    route:
    - destination:
        host: payment-service
        port:
          number: 8080
      weight: 100
EOF
```

## Question 6: CI/CD Pipeline Integration

Set up a complete CI/CD pipeline for microservices:

```bash
# Create Jenkins deployment for CI/CD
cat << EOF | kubectl apply -f -
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
      serviceAccountName: jenkins
      containers:
      - name: jenkins
        image: jenkins/jenkins:lts
        ports:
        - containerPort: 8080
        - containerPort: 50000
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        env:
        - name: JAVA_OPTS
          value: "-Djenkins.install.runSetupWizard=false"
        resources:
          requests:
            cpu: 200m
            memory: 512Mi
          limits:
            cpu: 500m
            memory: 1Gi
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins-data
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins-service
  namespace: cicd
spec:
  selector:
    app: jenkins
  ports:
  - port: 8080
    targetPort: 8080
    name: ui
  - port: 50000
    targetPort: 50000
    name: agents
  type: LoadBalancer
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-data
  namespace: cicd
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
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
  resources: ["pods", "services", "endpoints", "persistentvolumeclaims", "events", "configmaps", "secrets"]
  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "daemonsets", "replicasets", "statefulsets"]
  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
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
EOF

# Create Docker registry for storing images
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docker-registry
  namespace: cicd
  labels:
    app: docker-registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: docker-registry
  template:
    metadata:
      labels:
        app: docker-registry
    spec:
      containers:
      - name: registry
        image: registry:2.8
        ports:
        - containerPort: 5000
        volumeMounts:
        - name: registry-data
          mountPath: /var/lib/registry
        env:
        - name: REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY
          value: "/var/lib/registry"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
      volumes:
      - name: registry-data
        persistentVolumeClaim:
          claimName: registry-data
---
apiVersion: v1
kind: Service
metadata:
  name: docker-registry-service
  namespace: cicd
spec:
  selector:
    app: docker-registry
  ports:
  - port: 5000
    targetPort: 5000
  type: ClusterIP
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-data
  namespace: cicd
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
EOF

# Create ArgoCD for GitOps deployment
cat << EOF | kubectl apply -f -
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
      serviceAccountName: argocd-server
      containers:
      - name: argocd-server
        image: argoproj/argocd:v2.7.7
        ports:
        - containerPort: 8080
        - containerPort: 8083
        command:
        - argocd-server
        - --staticassets
        - /shared/app
        - --repo-server
        - argocd-repo-server:8081
        - --dex-server
        - http://argocd-dex-server:5556
        - --logformat
        - text
        - --loglevel
        - info
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: argocd-server-service
  namespace: cicd
spec:
  selector:
    app: argocd-server
  ports:
  - port: 8080
    targetPort: 8080
    name: http
  - port: 8083
    targetPort: 8083
    name: grpc
  type: LoadBalancer
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
EOF
```

## Verification Commands

```bash
# Check all microservices components
kubectl get all -n microservices
kubectl get all -n monitoring
kubectl get all -n ingress-system
kubectl get all -n cicd

# Test service discovery
kubectl exec -n microservices $(kubectl get pods -n microservices -l app=consul -o jsonpath='{.items[0].metadata.name}') -- consul members

# Test load balancing
kubectl exec -n microservices $(kubectl get pods -n microservices -l app=haproxy -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://localhost:80

# Check configuration management
kubectl get configmaps -n microservices
kubectl get secrets -n microservices

# Test monitoring stack
kubectl port-forward -n monitoring svc/prometheus-service 9090:9090
kubectl port-forward -n monitoring svc/grafana-service 3000:3000
kubectl port-forward -n monitoring svc/jaeger-service 16686:16686

# Test ingress and traffic management
kubectl get ingress -n microservices
kubectl describe ingress api-ingress -n microservices

# Check CI/CD components
kubectl get all -n cicd
kubectl port-forward -n cicd svc/jenkins-service 8080:8080
kubectl port-forward -n cicd svc/argocd-server-service 8080:8080
```
