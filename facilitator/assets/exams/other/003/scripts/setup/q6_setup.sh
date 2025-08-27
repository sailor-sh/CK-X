#!/bin/bash

# Question 6 Setup: Data Processing and Message Queues
# Deploy Redis, RabbitMQ and data processing components

set -e

echo "Setting up Data Processing and Message Queues..."

# Deploy Redis for caching and session storage
cat <<EOF | kubectl apply -f -
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
        image: redis:7.0-alpine
        ports:
        - containerPort: 6379
        args:
        - redis-server
        - --appendonly
        - "yes"
        - --requirepass
        - "\$(REDIS_PASSWORD)"
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-secret
              key: password
        volumeMounts:
        - name: redis-data
          mountPath: /data
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      volumes:
      - name: redis-data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: microservices
  labels:
    app: redis
spec:
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: redis
---
apiVersion: v1
kind: Secret
metadata:
  name: redis-secret
  namespace: microservices
type: Opaque
data:
  password: cmVkaXNwYXNzd29yZDEyMw== # redispassword123
EOF

# Deploy RabbitMQ for message queuing
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: rabbitmq
  namespace: microservices
  labels:
    app: rabbitmq
    tier: messaging
spec:
  serviceName: rabbitmq
  replicas: 1
  selector:
    matchLabels:
      app: rabbitmq
  template:
    metadata:
      labels:
        app: rabbitmq
        tier: messaging
    spec:
      containers:
      - name: rabbitmq
        image: rabbitmq:3.12-management-alpine
        ports:
        - containerPort: 5672
        - containerPort: 15672
        env:
        - name: RABBITMQ_DEFAULT_USER
          valueFrom:
            secretKeyRef:
              name: rabbitmq-secret
              key: username
        - name: RABBITMQ_DEFAULT_PASS
          valueFrom:
            secretKeyRef:
              name: rabbitmq-secret
              key: password
        volumeMounts:
        - name: rabbitmq-data
          mountPath: /var/lib/rabbitmq
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: rabbitmq-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq
  namespace: microservices
  labels:
    app: rabbitmq
spec:
  type: ClusterIP
  ports:
  - name: amqp
    port: 5672
    targetPort: 5672
  - name: management
    port: 15672
    targetPort: 15672
  selector:
    app: rabbitmq
---
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq-management
  namespace: microservices
  labels:
    app: rabbitmq
spec:
  type: NodePort
  ports:
  - name: management
    port: 15672
    targetPort: 15672
    nodePort: 31567
  selector:
    app: rabbitmq
---
apiVersion: v1
kind: Secret
metadata:
  name: rabbitmq-secret
  namespace: microservices
type: Opaque
data:
  username: cmFiYml0dXNlcg== # rabbituser
  password: cmFiYml0cGFzcw== # rabbitpass
EOF

# Deploy Event Processing Service
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: event-processor
  namespace: microservices
  labels:
    app: event-processor
    tier: processing
spec:
  replicas: 2
  selector:
    matchLabels:
      app: event-processor
  template:
    metadata:
      labels:
        app: event-processor
        tier: processing
    spec:
      serviceAccountName: microservice-sa
      containers:
      - name: event-processor
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        env:
        - name: REDIS_URL
          value: "redis://redis.microservices.svc.cluster.local:6379"
        - name: RABBITMQ_URL
          value: "amqp://rabbitmq.microservices.svc.cluster.local:5672"
        - name: RABBITMQ_USER
          valueFrom:
            secretKeyRef:
              name: rabbitmq-secret
              key: username
        - name: RABBITMQ_PASS
          valueFrom:
            secretKeyRef:
              name: rabbitmq-secret
              key: password
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-secret
              key: password
        envFrom:
        - configMapRef:
            name: microservice-config
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
  name: event-processor
  namespace: microservices
  labels:
    app: event-processor
spec:
  selector:
    app: event-processor
  ports:
  - name: http
    port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Deploy Data Analytics Job
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: data-analytics-job
  namespace: microservices
  labels:
    app: data-analytics
    tier: batch
spec:
  template:
    metadata:
      labels:
        app: data-analytics
        tier: batch
    spec:
      serviceAccountName: microservice-sa
      restartPolicy: OnFailure
      containers:
      - name: analytics
        image: alpine:3.18
        command:
        - /bin/sh
        - -c
        - |
          echo "Starting data analytics job..."
          echo "Connecting to Redis: \$REDIS_URL"
          echo "Connecting to RabbitMQ: \$RABBITMQ_URL"
          echo "Processing data for 30 seconds..."
          sleep 30
          echo "Data analytics job completed successfully!"
        env:
        - name: REDIS_URL
          value: "redis://redis.microservices.svc.cluster.local:6379"
        - name: RABBITMQ_URL
          value: "amqp://rabbitmq.microservices.svc.cluster.local:5672"
        - name: JOB_TYPE
          value: "analytics"
        envFrom:
        - configMapRef:
            name: microservice-config
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF

# Create CronJob for periodic data processing
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: data-cleanup-cronjob
  namespace: microservices
  labels:
    app: data-cleanup
    tier: batch
spec:
  schedule: "*/5 * * * *"  # Every 5 minutes
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: data-cleanup
            tier: batch
        spec:
          serviceAccountName: microservice-sa
          restartPolicy: OnFailure
          containers:
          - name: cleanup
            image: alpine:3.18
            command:
            - /bin/sh
            - -c
            - |
              echo "Starting periodic data cleanup..."
              echo "Current time: \$(date)"
              echo "Cleaning temporary data..."
              sleep 10
              echo "Data cleanup completed!"
            env:
            - name: CLEANUP_INTERVAL
              value: "5m"
            envFrom:
            - configMapRef:
                name: microservice-config
            resources:
              requests:
                memory: "32Mi"
                cpu: "25m"
              limits:
                memory: "64Mi"
                cpu: "50m"
EOF

echo "Data Processing and Message Queues setup completed successfully!"
