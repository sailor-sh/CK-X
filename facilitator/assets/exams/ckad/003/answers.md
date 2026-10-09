# CKAD-003 Advanced Application Development Lab - Answers

This document contains detailed solutions for all questions in the CKAD-003 lab.

## Question 1: Multi-Container Pod Patterns

Create a multi-container pod with sidecar pattern for logging:

```bash
# Create namespace
kubectl create namespace microservices

# Create ConfigMap for the sidecar container
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: sidecar-config
  namespace: microservices
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/app/app.log
      pos_file /var/log/fluentd-pos/app.log.pos
      tag app.log
      format none
    </source>
    <match app.log>
      @type stdout
    </match>
EOF

# Create multi-container pod with main app and logging sidecar
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-with-sidecar
  namespace: microservices
  labels:
    app: multi-container
spec:
  containers:
  - name: main-app
    image: nginx:1.20
    ports:
    - containerPort: 80
    volumeMounts:
    - name: app-logs
      mountPath: /var/log/app
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo 'App log entry' >> /var/log/app/app.log; sleep 10; done && nginx -g 'daemon off;'"]
  - name: log-sidecar
    image: fluent/fluentd:latest
    volumeMounts:
    - name: app-logs
      mountPath: /var/log/app
    - name: fluentd-config
      mountPath: /fluentd/etc
    - name: fluentd-pos
      mountPath: /var/log/fluentd-pos
  volumes:
  - name: app-logs
    emptyDir: {}
  - name: fluentd-config
    configMap:
      name: sidecar-config
  - name: fluentd-pos
    emptyDir: {}
EOF
```

## Question 2: Service Mesh Integration

Create microservices with service discovery:

```bash
# Create frontend deployment and service
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: microservices
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:1.20
        ports:
        - containerPort: 80
        env:
        - name: BACKEND_URL
          value: "http://backend-service:8080"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: microservices
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Create backend deployment and service
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: microservices
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: httpd:2.4
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: microservices
spec:
  selector:
    app: backend
  ports:
  - port: 8080
    targetPort: 80
  type: ClusterIP
EOF
```

## Question 3: ConfigMaps and Secrets Management

Create application configuration using ConfigMaps and Secrets:

```bash
# Create ConfigMap for application configuration
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: microservices
data:
  APP_NAME: "MyMicroservice"
  LOG_LEVEL: "INFO"
  CACHE_SIZE: "100"
  config.properties: |
    database.pool.size=10
    cache.timeout=300
    api.version=v1
EOF

# Create Secret for sensitive data
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: microservices
type: Opaque
data:
  DATABASE_URL: cG9zdGdyZXNxbDovL3VzZXI6cGFzc3dvcmRAZGI6NTQzMi9teWRi
  API_KEY: YWJjZGVmZ2hpams=
EOF

# Create deployment using ConfigMap and Secret
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-app
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: config-app
  template:
    metadata:
      labels:
        app: config-app
    spec:
      containers:
      - name: app
        image: nginx:1.20
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
      volumes:
      - name: config-volume
        configMap:
          name: app-config
EOF
```

## Question 4: Persistent Volume Claims

Create persistent storage for stateful applications:

```bash
# Create PersistentVolumeClaim
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: microservices
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
EOF

# Create deployment with persistent storage
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storage-app
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: storage-app
  template:
    metadata:
      labels:
        app: storage-app
    spec:
      containers:
      - name: app
        image: busybox:1.35
        command: ["/bin/sh"]
        args: ["-c", "while true; do echo 'Data: $(date)' >> /data/log.txt; sleep 30; done"]
        volumeMounts:
        - name: data-storage
          mountPath: /data
      volumes:
      - name: data-storage
        persistentVolumeClaim:
          claimName: data-pvc
EOF
```

## Question 5: Health Checks and Readiness Probes

Configure comprehensive health monitoring:

```bash
# Create deployment with health checks
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health-app
  namespace: microservices
spec:
  replicas: 2
  selector:
    matchLabels:
      app: health-app
  template:
    metadata:
      labels:
        app: health-app
    spec:
      containers:
      - name: app
        image: nginx:1.20
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 10
---
apiVersion: v1
kind: Service
metadata:
  name: health-service
  namespace: microservices
spec:
  selector:
    app: health-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

## Question 6: Resource Quotas and Limits

Implement resource management and quotas:

```bash
# Create namespace with resource restrictions
kubectl create namespace resource-limited

# Create ResourceQuota
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: resource-limited
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 2Gi
    limits.cpu: "4"
    limits.memory: 4Gi
    persistentvolumeclaims: "4"
    pods: "10"
EOF

# Create LimitRange
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: compute-limits
  namespace: resource-limited
spec:
  limits:
  - default:
      cpu: 200m
      memory: 256Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
  - max:
      cpu: 500m
      memory: 512Mi
    min:
      cpu: 50m
      memory: 64Mi
    type: Container
EOF

# Create deployment with resource limits
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: limited-app
  namespace: resource-limited
spec:
  replicas: 2
  selector:
    matchLabels:
      app: limited-app
  template:
    metadata:
      labels:
        app: limited-app
    spec:
      containers:
      - name: app
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
EOF
```

## Verification Commands

```bash
# Check all resources
kubectl get all -n microservices
kubectl get all -n resource-limited

# Check resource usage
kubectl top pods -n microservices
kubectl top pods -n resource-limited

# Check quotas
kubectl describe resourcequota compute-quota -n resource-limited
kubectl describe limitrange compute-limits -n resource-limited

# Check ConfigMaps and Secrets
kubectl get configmaps -n microservices
kubectl get secrets -n microservices

# Check PVC status
kubectl get pvc -n microservices
```
