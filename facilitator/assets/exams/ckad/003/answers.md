# Exam Solutions - CKAD Comprehensive Lab - 3

This document provides the solutions for the CKAD Comprehensive Lab - 3.

---

## Question 1: List Namespaces

**Solution:**
```bash
mkdir -p /opt/course/exam3/q01 && kubectl get ns > /opt/course/exam3/q01/namespaces
```

---

## Question 2: Create Pod and Status Command

**Solution:**
```bash
mkdir -p /opt/course/exam3/q02
kubectl -n ckad-q02 run pod1 --image=httpd:2.4.41-alpine --dry-run=client -oyaml > /tmp/pod1.yaml
# Edit /tmp/pod1.yaml to set container name to pod1-container
kubectl -n ckad-q02 create -f /tmp/pod1.yaml
# Create status command
cat > /opt/course/exam3/q02/pod1-status-command.sh <<EOF
#!/bin/bash
kubectl -n ckad-q02 get pod pod1 -o jsonpath="{.status.phase}"
EOF
chmod +x /opt/course/exam3/q02/pod1-status-command.sh
```

---

## Question 3: Job with Parallelism

**Solution:**
```bash
# Create the job.yaml
cat > /opt/course/exam3/q03/job.yaml <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: neb-new-job
  namespace: ckad-q03
spec:
  completions: 3
  parallelism: 2
  template:
    metadata:
      labels:
        id: awesome-job
    spec:
      containers:
      - name: neb-new-job-container
        image: busybox:1.31.0
        command: ["sleep", "2", "&&", "echo", "done"]
      restartPolicy: OnFailure
EOF

# Create the job
kubectl apply -f /opt/course/exam3/q03/job.yaml
```

---

## Question 4: Helm Management

**Solution:**
```bash
# 1. Setup helm repo
helm repo add killershell http://localhost:6000
helm repo update

# 2. Delete release internal-issue-report-apiv1
helm -n ckad-q04 delete internal-issue-report-apiv1

# 3. Upgrade release internal-issue-report-apiv2
helm -n ckad-q04 upgrade internal-issue-report-apiv2 killershell/nginx --version <newer_version>

# 4. Install a new release internal-issue-report-apache
helm -n ckad-q04 install internal-issue-report-apache killershell/apache --set replicaCount=2

# 5. Find and delete any releases stuck in pending-install state
helm -n ckad-q04 list -f pending-install -q | xargs helm -n ckad-q04 delete
```

---

## Question 5: ServiceAccount and Secret Token

**Solution:**
```bash
# Create ServiceAccount
kubectl -n ckad-q05 create sa neptune-sa-v2

# Create a secret for the ServiceAccount
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: neptune-sa-v2-token
  namespace: ckad-q05
  annotations:
    kubernetes.io/service-account.name: neptune-sa-v2
type: kubernetes.io/service-account-token
EOF

# Get the token from the secret and decode it
kubectl -n ckad-q05 get secret neptune-sa-v2-token -o jsonpath='{.data.token}' | base64 --decode > /opt/course/exam3/q05/token
```

---

## Question 6: ReadinessProbe

**Solution:**
```bash
kubectl -n ckad-q06 run pod6 --image=busybox:1.31.0 -- /bin/sh -c 'touch /tmp/ready && sleep 1d'
kubectl -n ckad-q06 patch pod pod6 --patch '{"spec":{"containers":[{"name":"pod6","readinessProbe":{"exec":{"command":["cat","/tmp/ready"]},"initialDelaySeconds":5,"periodSeconds":10}}]}}'
```

---

## Question 7: Move Pod Between Namespaces

**Solution:**
```bash
# Find the pod
POD_NAME=$(kubectl -n ckad-q07-source get pod -l id=webserver-sat-003 -o jsonpath='{.items[0].metadata.name}')

# Get the pod definition and change the namespace
kubectl -n ckad-q07-source get pod $POD_NAME -o yaml | sed 's/namespace: ckad-q07-source/namespace: ckad-q07-target/' | kubectl -n ckad-q07-target create -f -

# Delete the old pod
kubectl -n ckad-q07-source delete pod $POD_NAME
```

---

## Question 8: Deployment Rollback

**Solution:**
```bash
# Check the history of the deployment
kubectl -n ckad-q08 rollout history deployment api-new-c32

# Undo the last rollout
kubectl -n ckad-q08 rollout undo deployment api-new-c32
```

---

## Question 9: Convert Pod to Deployment

**Solution:**
```bash
# Get the pod definition and modify it to create a deployment
kubectl -n ckad-q09 get pod holy-api -o yaml > /tmp/holy-api.yaml

# Edit /tmp/holy-api.yaml to:
# 1. Change kind to Deployment
# 2. Add spec.replicas=3
# 3. Add spec.selector.matchLabels
# 4. Add securityContext to the container
# 5. Remove unnecessary fields from metadata and status

# Then apply the new deployment yaml and delete the pod
kubectl apply -f /tmp/holy-api.yaml
kubectl -n ckad-q09 delete pod holy-api

# Save the final deployment yaml
kubectl -n ckad-q09 get deployment holy-api -o yaml > /opt/course/exam3/q09/holy-api-deployment.yaml
```

---

## Question 10: Service and Logs

**Solution:**
```bash
# Create the pod
kubectl -n ckad-q10 run project-plt-6cc-api --image=nginx:1.17.3-alpine --labels=project=plt-6cc-api

# Create the service
kubectl -n ckad-q10 expose pod project-plt-6cc-api --name=project-plt-6cc-svc --port=3333 --target-port=80

# Test the service and save the output
kubectl -n ckad-q10 run test-curl --image=nginx:alpine -it --rm -- /bin/sh -c "curl project-plt-6cc-svc.ckad-q10:3333" > /opt/course/exam3/q10/service_test.html

# Get the pod logs
kubectl -n ckad-q10 logs project-plt-6cc-api > /opt/course/exam3/q10/service_test.log
```

---

## Question 11: Build Container Images

**Solution:**
```bash
# 1. Change the Dockerfile
sed -i 's/ENV SUN_CIPHER_ID=.*/ENV SUN_CIPHER_ID=5b9c1065-e39d-4a43-a04a-e59bcea3e03f/' /opt/course/exam3/q11/image/Dockerfile

# 2. Build and push with docker
sudo docker build -t registry.killer.sh:5000/sun-cipher:v1-docker /opt/course/exam3/q11/image
sudo docker push registry.killer.sh:5000/sun-cipher:v1-docker

# 3. Build and push with podman
sudo podman build -t registry.killer.sh:5000/sun-cipher:v1-podman /opt/course/exam3/q11/image
sudo podman push registry.killer.sh:5000/sun-cipher:v1-podman

# 4. Run the container with podman
sudo podman run -d --name sun-cipher registry.killer.sh:5000/sun-cipher:v1-podman

# 5. Get the logs
sudo podman logs sun-cipher > /opt/course/exam3/q11/logs
```

---

## Question 12: Storage: PV, PVC, and Pod Volume

**Solution:**
```bash
# Create the PV
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: earth-project-earthflower-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/Volumes/Data"
EOF

# Create the PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: earth-project-earthflower-pvc
  namespace: ckad-q12
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
EOF

# Create the Deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: project-earthflower
  namespace: ckad-q12
spec:
  replicas: 1
  selector:
    matchLabels:
      app: project-earthflower
  template:
    metadata:
      labels:
        app: project-earthflower
    spec:
      containers:
      - name: httpd
        image: httpd:2.4.41-alpine
        volumeMounts:
        - name: project-data
          mountPath: /tmp/project-data
      volumes:
      - name: project-data
        persistentVolumeClaim:
          claimName: earth-project-earthflower-pvc
EOF
```

---

## Question 13: StorageClass and PersistentVolumeClaim

**Solution:**
```bash
# Create the StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: moon-retain
provisioner: moon-retainer
reclaimPolicy: Retain
EOF

# Create the PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: moon-pvc-126
  namespace: ckad-q13
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: moon-retain
  resources:
    requests:
      storage: 3Gi
EOF

# Get the PVC events
kubectl -n ckad-q13 describe pvc moon-pvc-126 > /opt/course/exam3/q13/pvc-126-reason
```

---

## Question 14: Secret as Environment Variable and Volume

**Solution:**
```bash
# Create the secrets and configmap
kubectl -n ckad-q14 create secret generic secret1 --from-literal=user=test --from-literal=pass=pwd
kubectl -n ckad-q14 create configmap secret2 --from-literal=key1=value1

# Get the pod definition
kubectl -n ckad-q14 get pod secret-handler -o yaml > /opt/course/exam3/q14/secret-handler-new.yaml

# Edit /opt/course/exam3/q14/secret-handler-new.yaml to add envFrom and volumeMounts

# Apply the updated pod definition
kubectl apply -f /opt/course/exam3/q14/secret-handler-new.yaml
```

---

## Question 15: ConfigMap and ConfigMap Volume

**Solution:**
```bash
# Create the ConfigMap
kubectl -n ckad-q15 create configmap configmap-web-moon-html --from-file=/opt/course/exam3/q15/web-moon.html

# Save the ConfigMap definition
kubectl -n ckad-q15 get cm configmap-web-moon-html -o yaml > /opt/course/exam3/q15/configmap.yaml
```

---

## Question 16: Logging Sidecar Container

**Solution:**
```bash
# Get the deployment definition
kubectl -n ckad-q16 get deployment cleaner -o yaml > /opt/course/exam3/q16/cleaner-new.yaml

# Edit /opt/course/exam3/q16/cleaner-new.yaml to add the sidecar container

# Apply the updated deployment
kubectl apply -f /opt/course/exam3/q16/cleaner-new.yaml
```

---

## Question 17: InitContainer

**Solution:**
```bash
# Get the deployment definition
cp /opt/course/exam3/q17/test-init-container.yaml /opt/course/exam3/q17/test-init-container-new.yaml

# Edit /opt/course/exam3/q17/test-init-container-new.yaml to add the initContainer

# Apply the updated deployment
kubectl apply -f /opt/course/exam3/q17/test-init-container-new.yaml
```

---

## Question 18: Service Misconfiguration

**Solution:**
```bash
# Get the service definition
kubectl -n ckad-q18 get svc manager-api-svc -o yaml

# Edit the service to fix the selector
kubectl -n ckad-q18 edit svc manager-api-svc
```

---

## Question 19: Change Service Type: ClusterIP to NodePort

**Solution:**
```bash
# Edit the service and change the type to NodePort and set the nodePort
kubectl -n ckad-q19 edit svc jupiter-crew-svc
```

---

## Question 20: Add Liveness Probe

**Solution:**
```bash
# Get the deployment definition
cp /opt/course/exam3/p1/project-23-api.yaml /opt/course/exam3/p1/project-23-api-new.yaml

# Edit /opt/course/exam3/p1/project-23-api-new.yaml to add the livenessProbe

# Apply the updated deployment
kubectl apply -f /opt/course/exam3/p1/project-23-api-new.yaml
```

---

## Question 21: Deployment with ServiceAccount

**Solution:**
```bash
# Create the deployment
kubectl -n ckad-p2 create deployment sunny --image=nginx:1.17.3-alpine --replicas=4 -- sa=sa-sun-deploy

# Expose the deployment
kubectl -n ckad-p2 expose deployment sunny --name=sun-srv --port=9999 --target-port=80

# Create the status command script
echo 'kubectl -n ckad-p2 get pods -l app=sunny' > /opt/course/exam3/p2/sunny_status_command.sh
chmod +x /opt/course/exam3/p2/sunny_status_command.sh
```

---

## Question 22: Fix Readiness Probe Port

**Solution:**
```bash
# Edit the deployment to fix the readinessProbe port
kubectl -n ckad-p3 edit deployment earth-3cc-web

# Write the issue description
echo "The readinessProbe for the earth-3cc-web deployment was checking the wrong port." > /opt/course/exam3/p3/ticket-description.txt
```