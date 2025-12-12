# CKAD Exam Simulation - Questions & Answers

## A. Core Concepts (13%)
*Focus: Basic API interaction, namespaces, and pod creation.*

### Question 1: Namespace Management
Create a namespace named `ckad-ns-a`. Inside this namespace, run a pod named `web-core` using the image `nginx:alpine`.

**Answer:**
```bash
# Create the namespace
kubectl create namespace ckad-ns-a

# Run the pod in the namespace
kubectl run web-core --image=nginx:alpine -n ckad-ns-a

# Verify
kubectl get pods -n ckad-ns-a
```

---

### Question 2: Pod & JSONPath Extraction
List all pods in the `kube-system` namespace. Extract the *names* of the pods and their *creation timestamps*, writing the output to a file `/opt/course/1/pod-data.txt` in the format `pod_name creation_timestamp`.

**Answer:**
```bash
# Create the output directory if it doesn't exist
mkdir -p /opt/course/1

# Extract pod names and creation timestamps using kubectl and jsonpath
kubectl get pods -n kube-system -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.creationTimestamp}{"\n"}{end}' > /opt/course/1/pod-data.txt

# Verify
cat /opt/course/1/pod-data.txt
```

---

## B. Multi-Container Pods (10%)
*Focus: Sidecars, adapters, and shared volumes.*

### Question 3: Multi-Container Pod Setup
Create a pod named `multi-box` in the `default` namespace with two containers:
- Container 1: name `c1`, image `nginx`
- Container 2: name `c2`, image `busybox`, command `["/bin/sh", "-c", "while true; do echo hello; sleep 10; done"]`

**Answer:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-box
  namespace: default
spec:
  containers:
  - name: c1
    image: nginx
  - name: c2
    image: busybox
    command: ["/bin/sh", "-c", "while true; do echo hello; sleep 10; done"]
```

```bash
# Apply the manifest
kubectl apply -f multi-box.yaml

# Verify both containers are running
kubectl get pod multi-box
kubectl logs multi-box -c c2
```

---

### Question 4: Shared Volume (Sidecar Pattern)
Create a pod named `logger-pod` that uses a `emptyDir` volume.
- Container 1 (app): Image `busybox`, writes "logging info" to `/var/log/app.log` every 5 seconds.
- Container 2 (sidecar): Image `busybox`, tails/reads the `/var/log/app.log` file from the shared volume and sends it to stdout.

**Answer:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: logger-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c", "while true; do echo 'logging info' >> /var/log/app.log; sleep 5; done"]
    volumeMounts:
    - name: shared-log
      mountPath: /var/log
  - name: sidecar
    image: busybox
    command: ["/bin/sh", "-c", "tail -f /var/log/app.log"]
    volumeMounts:
    - name: shared-log
      mountPath: /var/log
  volumes:
  - name: shared-log
    emptyDir: {}
```

```bash
# Apply the manifest
kubectl apply -f logger-pod.yaml

# Verify the sidecar is reading logs
kubectl logs logger-pod -c sidecar
```

---

## C. Pod Design (20%)
*Focus: Labels, deployments, jobs, and cronjobs.*

### Question 5: Labels and Selectors
Create 3 pods named `pod-a`, `pod-b`, and `pod-c` with image `nginx`. Label `pod-a` and `pod-b` with `env=prod`. Then, execute a command to list only the pods with the label `env=prod`.

**Answer:**
```bash
# Create pod-a with label
kubectl run pod-a --image=nginx -l env=prod

# Create pod-b with label
kubectl run pod-b --image=nginx -l env=prod

# Create pod-c without label
kubectl run pod-c --image=nginx

# List pods with env=prod label
kubectl get pods -l env=prod

# Verify all three pods exist
kubectl get pods
```

---

### Question 6: Deployment & Scaling
Create a deployment named `web-deploy` using image `nginx:1.16` with 2 replicas. Once running, scale the deployment to 5 replicas.

**Answer:**
```bash
# Create deployment with 2 replicas
kubectl create deployment web-deploy --image=nginx:1.16 --replicas=2

# Verify initial replicas
kubectl get deployment web-deploy
kubectl get pods | grep web-deploy

# Scale to 5 replicas
kubectl scale deployment web-deploy --replicas=5

# Verify scaling
kubectl get deployment web-deploy
kubectl get pods | grep web-deploy
```

---

### Question 7: Rolling Updates & History
Update the `web-deploy` deployment to use image `nginx:1.17`. Verify the update strategy is set to `RollingUpdate`. After the update, record the rollout history.

**Answer:**
```bash
# Check current deployment strategy (should be RollingUpdate by default)
kubectl get deployment web-deploy -o jsonpath='{.spec.strategy.type}'

# Update the deployment image
kubectl set image deployment/web-deploy nginx=nginx:1.17

# Watch the rollout progress
kubectl rollout status deployment/web-deploy

# View the rollout history
kubectl rollout history deployment/web-deploy

# Verify the updated image
kubectl get deployment web-deploy -o jsonpath='{.spec.template.spec.containers[0].image}'
```

---

### Question 8: Rollbacks
Undo the latest update to `web-deploy`, reverting it back to the previous revision (`nginx:1.16`).

**Answer:**
```bash
# Check current revision
kubectl rollout history deployment/web-deploy

# Rollback to the previous revision
kubectl rollout undo deployment/web-deploy

# Verify the rollback
kubectl rollout status deployment/web-deploy
kubectl get deployment web-deploy -o jsonpath='{.spec.template.spec.containers[0].image}'

# Confirm we're back to nginx:1.16
kubectl get deployment web-deploy -o jsonpath='{.spec.template.spec.containers[0].image}' | grep 1.16
```

---

### Question 9: Jobs
Create a Job named `batch-job` with image `busybox` that runs the command `echo "Task Complete"; sleep 5`. Ensure the job automatically terminates (with a success) after completion.

**Answer:**
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-job
spec:
  template:
    spec:
      containers:
      - name: job-container
        image: busybox
        command: ["/bin/sh", "-c", "echo 'Task Complete'; sleep 5"]
      restartPolicy: Never
  backoffLimit: 2
```

```bash
# Apply the job manifest
kubectl apply -f batch-job.yaml

# Monitor job progress
kubectl get jobs
kubectl describe job batch-job

# View job logs
kubectl logs -l job-name=batch-job

# Verify successful completion
kubectl get job batch-job -o jsonpath='{.status.succeeded}'
```

---

### Question 10: CronJobs
Create a CronJob named `periodic-task` that runs every minute (`*/1 * * * *`). It should print the current date (`date`) using the `busybox` image.

**Answer:**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: periodic-task
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: cron-container
            image: busybox
            command: ["/bin/sh", "-c", "date"]
          restartPolicy: OnFailure
```

```bash
# Apply the cronjob manifest
kubectl apply -f periodic-task.yaml

# Verify the cronjob is created
kubectl get cronjobs
kubectl describe cronjob periodic-task

# Check for created jobs (may take up to a minute to appear)
kubectl get jobs | grep periodic-task

# View logs from a created job
kubectl get pods | grep periodic-task
kubectl logs <pod-name>
```

---

## D. Configuration (18%)
*Focus: ConfigMaps, Secrets, and Application Configuration.*

### Question 11: ConfigMaps (Environment Variables)
Create a ConfigMap named `app-config` with the key-value pair `APP_MODE=production`. Create a pod named `cm-pod` (image `nginx`) that consumes this ConfigMap key as an environment variable named `MODE`.

**Answer:**
```bash
# Create the ConfigMap
kubectl create configmap app-config --from-literal=APP_MODE=production

# Verify the ConfigMap
kubectl get configmap app-config
kubectl describe configmap app-config
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cm-pod
spec:
  containers:
  - name: nginx-container
    image: nginx
    env:
    - name: MODE
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_MODE
```

```bash
# Apply the pod manifest
kubectl apply -f cm-pod.yaml

# Verify the environment variable
kubectl exec cm-pod -- printenv | grep MODE
# Output should show: MODE=production
```

---

### Question 12: Secrets (Volume Mounts)
Create a Secret named `app-secret` containing `api-key=123456`. Create a pod named `sec-pod` (image `nginx`) and mount this secret as a volume at `/etc/app-secret` so the key is available as a file.

**Answer:**
```bash
# Create the Secret
kubectl create secret generic app-secret --from-literal=api-key=123456

# Verify the Secret
kubectl get secret app-secret
kubectl describe secret app-secret
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sec-pod
spec:
  containers:
  - name: nginx-container
    image: nginx
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/app-secret
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: app-secret
```

```bash
# Apply the pod manifest
kubectl apply -f sec-pod.yaml

# Verify the secret is mounted as a file
kubectl exec sec-pod -- ls -la /etc/app-secret/
kubectl exec sec-pod -- cat /etc/app-secret/api-key
# Output should show: 123456
```

---

### Question 13: Security Contexts (User Permissions)
Create a pod named `secure-pod` with image `busybox`. Configure the pod's **Security Context** so that the container runs with User ID `2000` (`runAsUser: 2000`) and the filesystem is read-only (`readOnlyRootFilesystem: true`).

**Answer:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsUser: 2000
    fsGroup: 2000
  containers:
  - name: busybox-container
    image: busybox
    command: ["/bin/sh", "-c", "sleep 3600"]
    securityContext:
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: tmp-volume
      mountPath: /tmp
  volumes:
  - name: tmp-volume
    emptyDir: {}
```

```bash
# Apply the pod manifest
kubectl apply -f secure-pod.yaml

# Verify the user context
kubectl exec secure-pod -- id
# Output should show: uid=2000

# Verify read-only filesystem (attempt to write should fail)
kubectl exec secure-pod -- touch /test.txt
# Should fail with "Read-only file system"

# Verify /tmp is writable (via mounted volume)
kubectl exec secure-pod -- touch /tmp/test.txt
# Should succeed
```

---

### Question 14: Service Accounts
Create a ServiceAccount named `backend-sa`. Create a pod named `backend-pod` (image `nginx`) that uses this specific ServiceAccount.

**Answer:**
```bash
# Create the ServiceAccount
kubectl create serviceaccount backend-sa

# Verify the ServiceAccount
kubectl get serviceaccount backend-sa
kubectl describe serviceaccount backend-sa
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: backend-pod
spec:
  serviceAccountName: backend-sa
  containers:
  - name: nginx-container
    image: nginx
```

```bash
# Apply the pod manifest
kubectl apply -f backend-pod.yaml

# Verify the pod is using the correct ServiceAccount
kubectl get pod backend-pod -o jsonpath='{.spec.serviceAccountName}'
# Output should show: backend-sa

# Verify the service account token is mounted
kubectl exec backend-pod -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/
```

---

### Question 15: Resource Quotas
Create a ResourceQuota named `ns-quota` in a new namespace `quota-ns` that limits the total number of pods allowed in the namespace to 5.

**Answer:**
```bash
# Create the namespace
kubectl create namespace quota-ns
```

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ns-quota
  namespace: quota-ns
spec:
  hard:
    pods: "5"
```

```bash
# Apply the ResourceQuota manifest
kubectl apply -f ns-quota.yaml

# Verify the ResourceQuota
kubectl describe quota ns-quota -n quota-ns

# Test: Try to create 6 pods (6th should fail)
for i in {1..6}; do kubectl run test-pod-$i --image=nginx -n quota-ns; done

# Check the quota status
kubectl describe quota ns-quota -n quota-ns
# Should show: Used: pods 5/5
```

---

## E. Observability (18%)
*Focus: Probes, Logging, and Debugging.*

### Question 16: Liveness Probes
Create a pod named `live-check` with image `busybox`. Configure a Liveness Probe that runs the command `cat /tmp/healthy`. Configure the container start command to create this file, sleep 30 seconds, and then delete it (to simulate failure).

**Answer:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: live-check
spec:
  containers:
  - name: busybox-container
    image: busybox
    command: ["/bin/sh", "-c", "touch /tmp/healthy; sleep 30; rm /tmp/healthy; sleep 600"]
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 2
      failureThreshold: 3
```

```bash
# Apply the pod manifest
kubectl apply -f live-check.yaml

# Monitor the pod status
kubectl get pod live-check
kubectl describe pod live-check

# Watch the liveness probe restarts
kubectl get pod live-check --watch
# After ~35 seconds, the probe should fail and trigger a restart
```

---

### Question 17: Readiness Probes
Create a pod named `ready-web` with image `nginx`. Configure a Readiness Probe that checks an HTTP GET request on port 80 at path `/`.

**Answer:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ready-web
spec:
  containers:
  - name: nginx-container
    image: nginx
    ports:
    - containerPort: 80
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 10
      timeoutSeconds: 2
      successThreshold: 1
      failureThreshold: 3
```

```bash
# Apply the pod manifest
kubectl apply -f ready-web.yaml

# Verify the readiness probe is working
kubectl get pod ready-web
kubectl describe pod ready-web

# Once ready, the pod should show "Ready 1/1"
kubectl get pod ready-web -w
```

---

## F. Services & Networking (13%)
*Focus: Service discovery and Network Policies.*

### Question 18: Service Exposure (ClusterIP)
Expose the `web-deploy` deployment (from Section C) as a Service named `web-svc` on port 80. The service type should be `ClusterIP`.

**Answer:**
```bash
# Expose the deployment as a ClusterIP service
kubectl expose deployment web-deploy --name=web-svc --port=80 --target-port=80 --type=ClusterIP

# Verify the service
kubectl get svc web-svc
kubectl describe svc web-svc

# Verify the service endpoints
kubectl get endpoints web-svc
```

Or using a manifest:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  type: ClusterIP
  selector:
    app: web-deploy
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

```bash
# Test service connectivity from within the cluster
kubectl run test-pod --image=nginx -it --rm -- curl http://web-svc:80
```

---

### Question 19: Network Policies (Deny All)
Create a NetworkPolicy named `default-deny` in the `default` namespace that denies all ingress traffic to all pods in that namespace.

**Answer:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

```bash
# Apply the NetworkPolicy manifest
kubectl apply -f default-deny-netpol.yaml

# Verify the NetworkPolicy
kubectl get networkpolicy
kubectl describe networkpolicy default-deny

# Test: Ingress traffic to pods should be denied
# Create a test pod and verify it cannot reach other pods
kubectl run test-deny --image=nginx
kubectl run test-target --image=nginx

# From test-deny pod, try to reach test-target (should timeout/fail)
kubectl exec test-deny -- curl --max-time 5 http://test-target
# Should timeout since ingress is denied
```

---

## G. State Persistence (8%)
*Focus: PVCs and Volume mounting.*

### Question 20: PersistentVolumeClaims
Create a PersistentVolumeClaim named `data-pvc` requesting `100Mi` of storage with access mode `ReadWriteOnce`. Mount this PVC to a pod named `storage-pod` at path `/data`.

**Answer:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
```

```bash
# Apply the PVC manifest
kubectl apply -f data-pvc.yaml

# Verify the PVC
kubectl get pvc
kubectl describe pvc data-pvc
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-pod
spec:
  containers:
  - name: storage-container
    image: nginx
    volumeMounts:
    - name: data-volume
      mountPath: /data
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: data-pvc
```

```bash
# Apply the pod manifest
kubectl apply -f storage-pod.yaml

# Verify the PVC is mounted
kubectl get pod storage-pod
kubectl describe pod storage-pod

# Test: Write data to the mounted volume
kubectl exec storage-pod -- sh -c 'echo "persistent data" > /data/test.txt'
kubectl exec storage-pod -- cat /data/test.txt
# Output should show: persistent data
```

---

## H. Helm
*Focus: Package Management.*

### Question 21: Helm Operations
Add the `bitnami` helm repository (`https://charts.bitnami.com/bitnami`). Search for the `nginx` chart, and install it into a new namespace `helm-ns` with the release name `my-web`.

**Answer:**
```bash
# Add the bitnami helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update helm repos
helm repo update

# Search for nginx chart
helm search repo bitnami/nginx

# Create the namespace
kubectl create namespace helm-ns

# Install the nginx chart
helm install my-web bitnami/nginx --namespace helm-ns

# Verify the installation
helm list -n helm-ns
helm status my-web -n helm-ns

# Verify the resources created
kubectl get all -n helm-ns
kubectl get svc -n helm-ns
```

---

## I. Custom Resource Definitions (CRDs)
*Focus: Extending Kubernetes.*

### Question 22: CRD & Custom Object
Create a CustomResourceDefinition (CRD) named `backups.stable.example.com`.
- Group: `stable.example.com`
- Version: `v1`
- Scope: `Namespaced`
- Names: `plural=backups`, `singular=backup`, `kind=Backup`, `shortNames=["bk"]`

After creating the CRD, create one instance (Custom Resource) of it named `my-backup`.

**Answer:**
```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: backups.stable.example.com
spec:
  group: stable.example.com
  names:
    kind: Backup
    plural: backups
    singular: backup
    shortNames:
    - bk
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
            properties:
              scheduleTime:
                type: string
              retentionDays:
                type: integer
```

```bash
# Apply the CRD manifest
kubectl apply -f backup-crd.yaml

# Verify the CRD is created
kubectl get crd
kubectl describe crd backups.stable.example.com
```

Now create an instance of the Backup custom resource:

```yaml
apiVersion: stable.example.com/v1
kind: Backup
metadata:
  name: my-backup
spec:
  scheduleTime: "2024-12-11T00:00:00Z"
  retentionDays: 30
```

```bash
# Apply the custom resource manifest
kubectl apply -f my-backup.yaml

# Verify the custom resource is created
kubectl get backups
kubectl get bk
kubectl describe backup my-backup

# You can also use the shortname
kubectl get bk my-backup
```

