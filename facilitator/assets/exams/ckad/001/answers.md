# CKAD Practice Exam - Answers

## Question 1: Create a deployment called nginx-deployment in the namespace dev with 3 replicas and image nginx:latest

```bash
# Create the namespace if it doesn't exist
kubectl create namespace dev

# Create the deployment with 3 replicas
kubectl create deployment nginx-deployment -n dev --image=nginx:latest --replicas=3
```

## Question 2: Create a PersistentVolume named 'pv-storage' with 1Gi capacity, access mode ReadWriteOnce, hostPath type at /mnt/data, and reclaim policy Retain

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-storage
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/data
```

Save this as `pv-storage.yaml` and apply:

```bash
kubectl apply -f pv-storage.yaml
```

## Question 3: Create a StorageClass named 'fast-storage' with provisioner 'kubernetes.io/no-provisioner' and volumeBindingMode 'WaitForFirstConsumer'

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

Save this as `storage-class.yaml` and apply:

```bash
kubectl apply -f storage-class.yaml
```

## Question 4: Create a PersistentVolumeClaim named 'pvc-app' that requests 500Mi of storage with ReadWriteOnce access mode and uses the 'fast-storage' StorageClass

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-app
  namespace: storage-test
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: fast-storage
```

Save this as `pvc.yaml` and apply:

```bash
kubectl apply -f pvc.yaml -n storage-test
```

## Question 5: The deployment 'broken-app' in namespace 'troubleshooting' is failing to start. Identify and fix the issue

Troubleshooting steps:
```bash
# Check the pods in the troubleshooting namespace
kubectl get pods -n troubleshooting

# Check the pod details for errors
kubectl describe pod -l app=broken-app -n troubleshooting

# Check logs of the failing pod
kubectl logs <pod-name> -n troubleshooting
```

Potential fixes:
1. If the image is incorrect: 
   ```bash
   kubectl set image deployments -n troubleshooting broken-app app=nginx:latest
   ```
2. If environment variables are missing:
   ```bash
   kubectl edit deployment broken-app -n troubleshooting
   ```
3. If resource limits are too low:
   ```bash
   kubectl patch deployment broken-app -n troubleshooting -p '{"spec":{"template":{"spec":{"containers":[{"name":"container-name","resources":{"limits":{"memory":"512Mi"}}}]}}}}'
   ```

## Question 6: Create a multi-container pod with sidecar logging pattern

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-pod
  namespace: troubleshooting
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: log-volume
      mountPath: /var/my-log
  - name: sidecar
    image: busybox
    command: ["sh", "-c", "while true; do date >> /var/my-log/date.log; sleep 10; done"]
    volumeMounts:
    - name: log-volume
      mountPath: /var/my-log
  volumes:
  - name: log-volume
    emptyDir: {}
```

Save this as `sidecar-pod.yaml` and apply:

```bash
kubectl apply -f sidecar-pod.yaml
```

You can verify the pod is working correctly:

```bash
# Check that both containers are running in the pod
kubectl get pod sidecar-pod -n troubleshooting

# Verify the shared volume is mounted and the log file is being written
kubectl exec -it sidecar-pod -n troubleshooting -c nginx -- cat /var/my-log/date.log

# Check events related to the pod
kubectl describe pod sidecar-pod -n troubleshooting
```

## Question 7: Service 'web-service' in namespace 'troubleshooting' is not routing traffic to pods properly. Identify and fix the issue

Troubleshooting steps:
```bash
# Check the service configuration
kubectl get svc web-service -n troubleshooting

# Examine the service details to identify selector and port configuration issues
kubectl describe svc web-service -n troubleshooting

```

Solution approach based on typical issues:

1. If the service selector doesn't match any pod labels, fix the service selector:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: troubleshooting
spec:
  selector:
    app: web-app  
  ports:
  - port: 80
    targetPort: 80
```

2. Save as `fixed-service.yaml` and apply:
```bash
kubectl apply -f fixed-service.yaml
```

## Question 8: Pod 'logging-pod' in namespace 'troubleshooting' is consuming excessive CPU resources. Set appropriate CPU and memory limits

Solution:
1. After identifying which container is causing high CPU usage, edit the pod to add resource limits:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: logging-pod
  namespace: troubleshooting
spec:
  containers:
  - name: <container-name>
    # ... existing container configuration ...
    resources:
      limits:
        cpu: 100m
        memory: 50Mi
```

Edit the pod to add resource limits and will be saved to tmp/<file.yaml>
```
kubectl replace -f tmp/<file.yaml> --force
```

## Question 9: Create a ConfigMap named 'app-config' in namespace 'workloads' containing the following key-value pairs: APP_ENV=production, LOG_LEVEL=info. Then create a Pod named 'config-pod' using 'nginx' image that mounts these configurations as environment variables

```bash
# Create the ConfigMap
kubectl create configmap app-config -n workloads --from-literal=APP_ENV=production --from-literal=LOG_LEVEL=info
```

Create the Pod with ConfigMap environment variables:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
  namespace: workloads
spec:
  containers:
  - name: nginx
    image: nginx
    env:
    - name: APP_ENV
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_ENV
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: LOG_LEVEL
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
```

Save as `config-pod.yaml` and apply:
```bash
kubectl apply -f config-pod.yaml
```

## Question 10: Create a Secret named 'db-credentials' in namespace 'workloads' containing username=admin and password=securepass. Then create a Pod named 'secure-pod' using 'mysql:5.7' image with these credentials set as environment variables DB_USER and DB_PASSWORD

```bash
# Create the Secret
kubectl create secret generic db-credentials -n workloads --from-literal=username=admin --from-literal=password=securepass
```

Create the Pod with Secret environment variables:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: workloads
spec:
  containers:
  - name: mysql
    image: mysql:latest
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
    - name: MYSQL_ROOT_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
  restartPolicy: Always
```

Save as `secure-pod.yaml` and apply:
```bash
kubectl apply -f secure-pod.yaml
```

## Question 11: Create a CronJob named 'log-cleaner' in namespace 'workloads' that runs hourly to clean up log files

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: log-cleaner
  namespace: workloads
spec:
  schedule: "0 * * * *"  # Run every hour at minute 0
  concurrencyPolicy: Forbid  # Skip new job if previous is running
  successfulJobsHistoryLimit: 3  # Keep 3 successful job completions
  failedJobsHistoryLimit: 1  # Keep 1 failed job
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: log-cleaner
            image: busybox
            command: ["/bin/sh", "-c"]
            args:
            - find /var/log -type f -name "*.log" -mtime +7 -delete
          restartPolicy: OnFailure
```

Save this as `log-cleaner-cronjob.yaml` and apply:

```bash
kubectl apply -f log-cleaner-cronjob.yaml
```

You can check the cron job configuration:
```bash
kubectl get cronjob log-cleaner -n workloads -o yaml
```

## Question 12: Create a Pod named 'health-pod' in namespace 'workloads' using 'nginx' image with a liveness probe that checks the path /healthz on port 80 every 15 seconds, and a readiness probe that checks port 80 every 10 seconds

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: health-pod
  namespace: workloads
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /healthz
        port: 80
      initialDelaySeconds: 30
      periodSeconds: 15
    readinessProbe:
      tcpSocket:
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 10
```

Save as `health-pod.yaml` and apply:
```bash
kubectl apply -f health-pod.yaml
```

## Question 13: Create a ClusterRole named 'pod-reader' that allows getting, watching, and listing pods. Then create a ClusterRoleBinding named 'read-pods' that grants this role to the user 'jane' in the namespace 'cluster-admin'

```bash
# Create the ClusterRole
kubectl create clusterrole pod-reader --verb=get,watch,list --resource=pods
```

Or using YAML:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

Create the ClusterRoleBinding:
```bash
kubectl create clusterrolebinding read-pods --clusterrole=pod-reader --user=jane --namespace=cluster-admin
```

Or using YAML:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-pods
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Save YAML files and apply them:
```bash
kubectl apply -f cluster-role.yaml
kubectl apply -f cluster-role-binding.yaml
```

## Question 14: Deploy the Bitnami Nginx chart in the 'web' namespace using Helm

```bash
# Create the namespace if it doesn't exist
kubectl create namespace web

# Add the Bitnami charts repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update Helm repositories
helm repo update

# Install Bitnami's Nginx chart with 2 replicas
helm install nginx bitnami/nginx --namespace web --set replicaCount=2

# Verify the deployment
kubectl get pods -n web
kubectl get svc -n web
```

You can inspect the installation and configuration:
```bash
helm list -n web
kubectl get deployment -n web
```

## Question 15: Create a CRD (CustomResourceDefinition) for a new resource type 'Backup' in API group 'data.example.com' with version 'v1alpha1' that includes fields 'spec.source' and 'spec.destination'

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: backups.data.example.com
spec:
  group: data.example.com
  names:
    kind: Backup
    listKind: BackupList
    plural: backups
    singular: backup
  scope: Namespaced
  versions:
  - name: v1alpha1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              source:
                type: string
              destination:
                type: string
            required: ["source", "destination"]
```

Save as `backup-crd.yaml` and apply:
```bash
kubectl apply -f backup-crd.yaml
```

## Question 16: Create a NetworkPolicy named 'allow-traffic' in namespace 'networking' that allows traffic to pods with label 'app=web' only from pods with label 'tier=frontend' on port 80

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-traffic
  namespace: networking
spec:
  podSelector:
    matchLabels:
      app: web
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
```

Save as `network-policy.yaml` and apply:
```bash
kubectl apply -f network-policy.yaml
```

## Question 17: Create a ClusterIP service named 'internal-app' in namespace 'networking' that routes traffic to pods with label 'app=backend' on port 8080, exposing the service on port 80

Or using YAML:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: internal-app
  namespace: networking
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
```

Save as `internal-service.yaml` and apply:
```bash
kubectl apply -f internal-service.yaml
```

## Question 18: Create a NodePort service named public-web in namespace networking that will expose the web-frontend deployment to external users.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: public-web
  namespace: networking
spec:
  type: NodePort
  selector:
    app: web-frontend 
  ports:
    - name: http
      protocol: TCP
      port: 80           
      targetPort: 8080  
      nodePort: 30080    

```

Save as `loadbalancer-service.yaml` and apply:
```bash
kubectl apply -f loadbalancer-service.yaml
```

## Question 19: Create an Ingress resource named 'api-ingress' in namespace 'networking' that routes traffic from 'api.example.com' to the service 'api-service' on port 80

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  namespace: networking
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
```

Save as `ingress.yaml` and apply:
```bash
kubectl apply -f ingress.yaml
```

## Question 20: Create a simple Kubernetes Job named 'hello-job' that executes a command and completes

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: hello-job
  namespace: networking
spec:
  activeDeadlineSeconds: 30
  template:
    spec:
      containers:
      - name: hello
        image: busybox
        command: ["sh", "-c", "echo 'Hello from Kubernetes job!'"]
      restartPolicy: Never
  backoffLimit: 0
```

Save this as `hello-job.yaml` and apply:

```bash
kubectl apply -f hello-job.yaml
```

You can check the job's status and output:
```bash
# Check job status
kubectl get jobs -n networking

# View the pod created by the job
kubectl get pods -n networking -l job-name=hello-job

# Check the logs to see the output message
kubectl logs -n networking -l job-name=hello-job
```

## Question 21: Work with the Open Container Initiative (OCI) format

```bash
# Pull the image
docker pull nginx:latest

# Save the image to a tarball
docker save nginx:latest -o /tmp/nginx-image.tar

# Create the OCI directory
mkdir -p /root/oci-images

# Extract the tarball to the OCI directory
tar -xf /tmp/nginx-image.tar -C /root/oci-images

# Clean up the tarball
rm /tmp/nginx-image.tar
```

Check the result:
```bash
ls -la /root/oci-images
cat /root/oci-images/index.json  # Verify it's in OCI format
```