# CKA Advanced Administration Lab - Answers

## Question 1: Network Policy Implementation

Create a NetworkPolicy that allows ingress only from frontend pods:

```bash
# Create namespace
kubectl create namespace production

# Create NetworkPolicy
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-netpol
  namespace: production
spec:
  podSelector: {}
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
  - {}
EOF

# Test with frontend pod
kubectl run frontend-test --image=nginx --labels=app=frontend -n production

# Test with non-frontend pod
kubectl run backend-test --image=nginx --labels=app=backend -n production
```

## Question 2: ETCD Backup

Create a backup of the etcd database:

```bash
# Find etcd pod and certificates
ETCD_POD=$(kubectl get pods -n kube-system | grep etcd | awk '{print $1}')

# Get etcd configuration
kubectl describe pod $ETCD_POD -n kube-system

# Create backup using etcdctl
ETCDCTL_API=3 etcdctl snapshot save /opt/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify backup
ETCDCTL_API=3 etcdctl snapshot status /opt/etcd-backup.db
```

## Question 3: Web Server Deployment with Resources and Probes

Create a comprehensive deployment with resource management:

```bash
# Create namespace
kubectl create namespace web-app

# Create deployment
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
  namespace: web-app
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: web-server
  template:
    metadata:
      labels:
        app: web-server
    spec:
      containers:
      - name: nginx
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
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 20
EOF

# Create service
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: web-app
spec:
  selector:
    app: web-server
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

## Question 4: Node Troubleshooting

Fix a NotReady node:

```bash
# List nodes to find the problematic one
kubectl get nodes

# Describe the node to see conditions
kubectl describe node <node-name>

# SSH to the node (if possible) or use kubectl debug
# Check kubelet status
systemctl status kubelet

# Check kubelet logs
journalctl -u kubelet -f

# Common fixes:
# 1. Restart kubelet service
systemctl restart kubelet

# 2. Check disk space
df -h

# 3. Check if container runtime is running
systemctl status containerd  # or docker

# 4. Check network connectivity
ping 8.8.8.8

# Verify node is back to Ready
kubectl get nodes
```

## Question 5: StatefulSet with Persistent Storage

Create a MySQL StatefulSet with persistent volumes:

```bash
# Create namespace
kubectl create namespace database

# Create StorageClass if needed
cat << EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

# Create StatefulSet
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql-cluster
  namespace: database
spec:
  serviceName: mysql-service
  replicas: 2
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: secretpassword
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: mysql-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: fast-storage
      resources:
        requests:
          storage: 1Gi
EOF

# Create headless service
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: database
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
EOF
```

## Question 6: DaemonSet for Log Collection

Create a DaemonSet that runs on all nodes:

```bash
# Create namespace
kubectl create namespace monitoring

# Create DaemonSet
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      hostNetwork: true
      nodeSelector:
        kubernetes.io/os: linux
      containers:
      - name: fluentd
        image: fluentd:latest
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: dockerlogs
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: dockerlogs
        hostPath:
          path: /var/lib/docker/containers
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
EOF

# Verify DaemonSet is running on all nodes
kubectl get ds -n monitoring
kubectl get pods -n monitoring -o wide
```

## Verification Commands

```bash
# Check all resources
kubectl get all -A

# Verify network policies
kubectl get networkpolicy -A

# Check node status
kubectl get nodes

# Verify StatefulSet and PVCs
kubectl get sts,pvc -n database

# Check DaemonSet distribution
kubectl get ds -n monitoring
kubectl get pods -n monitoring -o wide
```
