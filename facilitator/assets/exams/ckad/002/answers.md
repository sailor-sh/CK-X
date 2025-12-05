# CKAD-002 Lab Answers

This document contains solutions for all questions in the CKAD-002 lab

## Question 1: Core Concepts

Create a namespace and a pod with labels:

```bash
# Create namespace
kubectl create namespace core-concepts

# Create pod with labels
kubectl run nginx-pod --image=nginx -n core-concepts --labels="app=web,env=prod"

# Or using YAML:
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: core-concepts
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  namespace: core-concepts
  labels:
    app: web
    env: prod
spec:
  containers:
  - name: nginx
    image: nginx
EOF
```

## Question 2: Multi-container Pods

Create a multi-container pod with a shared volume:

```bash
# Create namespace
kubectl create namespace multi-container

# Create multi-container pod with shared volume
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: multi-container
---
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
  namespace: multi-container
spec:
  containers:
  - name: main-container
    image: nginx
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
    - name: log-volume
      mountPath: /var/log/nginx
      subPath: nginx
  - name: sidecar-container
    image: busybox
    command: ['sh', '-c', 'while true; do echo $(date) >> /var/log/app.log; sleep 5; done']
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
  volumes:
  - name: log-volume
    emptyDir: {}
EOF
```

## Question 3: Pod Design - Deployment & Service

Create a deployment and a service:

```bash
# Create namespace
kubectl create namespace pod-design

# Create deployment and service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: pod-design
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: pod-design
  labels:
    app: frontend
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
      tier: frontend
  template:
    metadata:
      labels:
        app: frontend
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.19.0
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
  namespace: pod-design
spec:
  selector:
    app: frontend
    tier: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

## Question 4: Configuration - ConfigMaps & Secrets

Create ConfigMap, Secret, and Pod using them:

```bash
# Create namespace
kubectl create namespace configuration

# Create ConfigMap
kubectl create configmap app-config -n configuration \
  --from-literal=DB_HOST=mysql \
  --from-literal=DB_PORT=3306 \
  --from-literal=DB_NAME=myapp

# Create Secret
kubectl create secret generic app-secret -n configuration \
  --from-literal=DB_USER=admin \
  --from-literal=DB_PASSWORD=s3cr3t

# Create Pod using ConfigMap and Secret
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  namespace: configuration
spec:
  containers:
  - name: nginx
    image: nginx
    envFrom:
    - configMapRef:
        name: app-config
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/app-secret
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: app-secret
EOF
```

## Question 5: Observability - Probes & Resource Limits

Create a pod with liveness/readiness probes and resource limits:

```bash
# Create namespace
kubectl create namespace observability

# Create pod with probes and resource limits
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: observability
---
apiVersion: v1
kind: Pod
metadata:
  name: probes-pod
  namespace: observability
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
    livenessProbe:
      httpGet:
        path: /healthz
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 5
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 3
EOF
```

## Question 6: Services - Different Service Types

Create deployment with different service types:

```bash
# Create namespace
kubectl create namespace services

# Create deployment and three different services
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: services
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: services
spec:
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
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc-cluster
  namespace: services
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc-nodeport
  namespace: services
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc-lb
  namespace: services
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF
```

## Question 7: State - PV, PVC, and StatefulApp

Set up persistent storage for MySQL:

```bash
# Create namespace
kubectl create namespace state

# Create PV, PVC, and MySQL pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: state
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: db-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-pvc
  namespace: state
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: db-pod
  namespace: state
spec:
  containers:
  - name: mysql
    image: mysql:5.7
    env:
    - name: MYSQL_ROOT_PASSWORD
      value: rootpassword
    - name: MYSQL_DATABASE
      value: mydb
    - name: MYSQL_USER
      value: myuser
    - name: MYSQL_PASSWORD
      value: mypassword
    volumeMounts:
    - name: mysql-storage
      mountPath: /var/lib/mysql
  volumes:
  - name: mysql-storage
    persistentVolumeClaim:
      claimName: db-pvc
EOF
```

## Question 8: Pod Design - CronJob

Create a CronJob:

```bash
# Ensure namespace exists (should be created from Question 3)
kubectl get namespace pod-design || kubectl create namespace pod-design

# Create CronJob
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
  namespace: pod-design
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      activeDeadlineSeconds: 100
      template:
        spec:
          containers:
          - name: backup
            image: busybox
            command: ['sh', '-c', 'echo Backup started: $(date); sleep 30; echo Backup completed: $(date)']
          restartPolicy: OnFailure
EOF
```

## Question 9: Troubleshooting a Deployment

Fix a broken deployment (assuming it's already created but not working):

```bash
# First check what's wrong with the deployment
kubectl describe deployment broken-deployment -n troubleshooting

# Common fixes might include:

# Fix 1: Correct the image if it's incorrect
kubectl set image deployment/broken-deployment nginx=nginx:1.19 -n troubleshooting

# Fix 2: If resource requests are too high
kubectl patch deployment broken-deployment -n troubleshooting --patch '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"requests":{"cpu":"100m","memory":"128Mi"},"limits":{"cpu":"200m","memory":"256Mi"}}}]}}}}'

# Fix 3: If there's a configuration issue in the pod template
kubectl edit deployment broken-deployment -n troubleshooting

# Fix 4: If a network policy is blocking traffic
kubectl get networkpolicies -n troubleshooting
kubectl delete networkpolicy restrictive-policy -n troubleshooting

# Verify the fix
kubectl rollout status deployment/broken-deployment -n troubleshooting
```

## Question 10: Networking - NetworkPolicy

Create pods and a NetworkPolicy:

```bash
# Create namespace
kubectl create namespace networking

# Create the three pods
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: networking
---
apiVersion: v1
kind: Pod
metadata:
  name: secure-db
  namespace: networking
  labels:
    app: db
spec:
  containers:
  - name: postgres
    image: postgres:12
    env:
    - name: POSTGRES_PASSWORD
      value: password
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: networking
  labels:
    role: frontend
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: monitoring
  namespace: networking
  labels:
    role: monitoring
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-network-policy
  namespace: networking
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 5432
  egress:
  - to:
    - podSelector:
        matchLabels:
          role: monitoring
    ports:
    - protocol: TCP
      port: 8080
EOF
```

## Question 11: Security Context

Create a Pod with security configurations:

```bash
# Create namespace
kubectl create namespace security

# Create secure pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: security
---
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
  namespace: security
spec:
  securityContext:
    runAsUser: 1000
    runAsNonRoot: true
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      capabilities:
        drop: ["ALL"]
      readOnlyRootFilesystem: true
      runAsNonRoot: true
EOF
```

## Question 12: Docker Basics

Create a simple Docker image and run it:

```bash
# Create the Dockerfile
cat > /tmp/Dockerfile << 'EOF'
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
EOF

# Create the HTML file
cat > /tmp/index.html << 'EOF'
<!DOCTYPE html>
<html>
<body>
<h1>Hello from CKAD Docker Question!</h1>
</body>
</html>
EOF

# Build the Docker image
docker build -t my-nginx:v1 -f /tmp/Dockerfile /tmp

# Run the container
docker run -d --name my-web -p 8080:80 my-nginx:v1

# Verify the container is running
docker ps | grep my-web
```

## Question 13: Jobs

Create a Job with specific configurations:

```bash
# Create namespace
kubectl create namespace jobs

# Create Job
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: jobs
---
apiVersion: batch/v1
kind: Job
metadata:
  name: data-processor
  namespace: jobs
spec:
  backoffLimit: 4
  activeDeadlineSeconds: 30
  template:
    spec:
      containers:
      - name: processor
        image: busybox
        command: ['sh', '-c', 'for i in $(seq 1 5); do echo Processing item $i; sleep 2; done']
      restartPolicy: Never
EOF
```

## Question 14: Init Containers

Create a Pod with init container and service:

```bash
# Create namespace
kubectl create namespace init-containers

# Create Pod with init container and Service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: init-containers
---
apiVersion: v1
kind: Service
metadata:
  name: myservice
  namespace: init-containers
spec:
  selector:
    app: myservice
  ports:
  - port: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: app-with-init
  namespace: init-containers
spec:
  containers:
  - name: main-container
    image: nginx
    volumeMounts:
    - name: log-volume
      mountPath: /shared
  initContainers:
  - name: sidecar-container
    image: busybox
    command: ['sh', '-c', 'until nslookup myservice; do echo waiting for myservice; sleep 2; done']
    volumeMounts:
    - name: log-volume
      mountPath: /shared
  volumes:
  - name: log-volume
    emptyDir: {}
EOF
```

## Question 15 - Helm Basics

The task is to perform basic Helm operations including creating a namespace, adding a repository, installing a chart, and saving release notes.

```bash
# Step 1: Create the namespace
kubectl create namespace helm-basics

# Step 2: Add the Bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Step 3: Install the nginx chart
helm install nginx-release bitnami/nginx --namespace helm-basics

# Step 4: Save the release notes to a file
helm get notes nginx-release --namespace helm-basics > /tmp/release-notes.txt
```

These commands:
1. Create a namespace called `helm-basics`
2. Add the Bitnami Helm chart repository and update it to get the latest charts
3. Install the nginx chart from Bitnami in the helm-basics namespace with the release name "nginx-release"
4. Save the release notes to /tmp/release-notes.txt using the `helm get notes` command

## Question 16: Health Checks

Create a Pod with multiple health probes:

```bash
# Create namespace
kubectl create namespace health-checks

# Create Pod with startup, liveness, and readiness probes
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: health-checks
---
apiVersion: v1
kind: Pod
metadata:
  name: health-check-pod
  namespace: health-checks
spec:
  containers:
  - name: nginx
    image: nginx
    startupProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 3
      failureThreshold: 3
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 15
      periodSeconds: 5
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 3
      failureThreshold: 3
EOF
```

## Question 17: Pod Lifecycle

Create a Pod with lifecycle hooks:

```bash
# Create namespace
kubectl create namespace pod-lifecycle

# Create Pod with lifecycle hooks
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: pod-lifecycle
---
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-pod
  namespace: pod-lifecycle
spec:
  containers:
  - name: nginx
    image: nginx
    lifecycle:
      postStart:
        exec:
          command: ["/bin/sh", "-c", "echo 'Welcome to the pod!' > /usr/share/nginx/html/welcome.txt"]
      preStop:
        exec:
          command: ["/bin/sh", "-c", "sleep 10"]
  terminationGracePeriodSeconds: 30
EOF
```

## Question 18: Custom Resource Definitions

Create a CRD and a custom resource:

```bash
# Create namespace
kubectl create namespace crd-demo

# Create the Custom Resource Definition (CRD)
cat <<EOF | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: applications.training.ckad.io
spec:
  group: training.ckad.io
  names:
    kind: Application
    plural: applications
    singular: application
    shortNames:
    - app
  scope: Namespaced
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required: ["image", "replicas"]
            properties:
              image:
                type: string
              replicas:
                type: integer
                minimum: 1
EOF

# Create the Custom Resource
cat <<EOF | kubectl apply -f -
apiVersion: training.ckad.io/v1
kind: Application
metadata:
  name: my-app
  namespace: crd-demo
spec:
  image: nginx:1.19.0
  replicas: 3
EOF

# Verify the resources
kubectl get crd applications.training.ckad.io
kubectl get application -n crd-demo
```

## Question 19: Custom Column Output

Use kubectl custom columns to extract pod information:

```bash
# Create namespace (should already be set up by the test environment)
kubectl create namespace custom-columns-demo

# First, let's see what pods we have to work with
kubectl get pods -n custom-columns-demo

# Create the basic custom column output showing pods from all namespaces
# Format: POD NAME, NAMESPACE, and PRIMARY CONTAINER IMAGE
kubectl get pods -A -o custom-columns="POD:.metadata.name,NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[0].image" > /tmp/pod-images.txt

# Verify the basic output
cat /tmp/pod-images.txt

# For the second requirement, we need to handle multi-container pods
# Option 1: Using jsonpath to get comma-separated list of all container images
kubectl get pods -A -o jsonpath="{range .items[*]}{.metadata.name},{.metadata.namespace},{range .spec.containers[*]}{.image}{','}{end}{'\n'}{end}" > /tmp/all-container-images.txt

# Option 2: Using a more advanced approach with a script
cat <<'EOF' > /tmp/get-pod-images.sh
#!/bin/bash
echo "POD,NAMESPACE,IMAGES"
kubectl get pods -A -o json | jq -r '.items[] | .metadata.name + "," + .metadata.namespace + "," + (.spec.containers | map(.image) | join(","))'
EOF

chmod +x /tmp/get-pod-images.sh
/tmp/get-pod-images.sh > /tmp/all-container-images.txt

# Verify the multi-container output
cat /tmp/all-container-images.txt

# Check that our outputs contain the expected data
grep "multi-container-pod" /tmp/all-container-images.txt
```

This solution creates two output files:
1. `/tmp/pod-images.txt` - Shows all pods with their names, namespaces, and primary container images
2. `/tmp/all-container-images.txt` - Shows all pods with all container images, properly handling multi-container pods

## Question 20: Pod Configuration

Create a Pod that uses ConfigMaps and Secrets for configuration:

```bash
# Create namespace
kubectl create namespace pod-configuration

# Create ConfigMap with database connection settings
kubectl create configmap app-config -n pod-configuration \
  --from-literal=DB_HOST=db.example.com \
  --from-literal=DB_PORT=5432

# Verify the ConfigMap was created correctly
kubectl get configmap app-config -n pod-configuration -o yaml

# Create Secret with API credentials
kubectl create secret generic app-secret -n pod-configuration \
  --from-literal=API_KEY=my-api-key \
  --from-literal=API_SECRET=my-api-secret

# Verify the Secret was created (note values will be base64 encoded)
kubectl get secret app-secret -n pod-configuration -o yaml

# Create Pod with environment variables and volume mounts
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
  namespace: pod-configuration
spec:
  containers:
  - name: nginx
    image: nginx
    # Direct environment variables
    env:
    - name: APP_ENV
      value: production
    - name: DEBUG
      value: "false"
    # Environment variables from ConfigMap
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DB_HOST
    - name: DB_PORT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DB_PORT
    # Environment variables from Secret
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: API_KEY
    - name: API_SECRET
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: API_SECRET
    # Mount ConfigMap as a volume
    volumeMounts:
    - name: config-volume
      mountPath: /etc/app-config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
EOF

# Verify the Pod has been created
kubectl get pod config-pod -n pod-configuration

# Verify environment variables within the Pod
kubectl exec config-pod -n pod-configuration -- env | grep -E 'APP_ENV|DEBUG|DB_|API_'

# Verify the ConfigMap is mounted as a volume
kubectl exec config-pod -n pod-configuration -- ls -la /etc/app-config
kubectl exec config-pod -n pod-configuration -- cat /etc/app-config/DB_HOST
```

This solution demonstrates:
1. Creating a ConfigMap with database connection settings
2. Creating a Secret with API credentials
3. Configuring a Pod with:
   - Direct environment variables (APP_ENV, DEBUG)
   - Environment variables from ConfigMap (DB_HOST, DB_PORT)
   - Environment variables from Secret (API_KEY, API_SECRET)
   - Mounting the ConfigMap as a volume at /etc/app-config
4. Verification commands to ensure everything is working correctly 