# Berlin Lab - Solutions

## Question 1: The deployment 'broken-app' in namespace 'troubleshooting' is failing to start. Identify and fix the issue

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

## Question 2: The deployment 'nice-app' in namespace 'app' is not exposed, cause the service is not routing traffic correctly. Identify and fix the issue

Troubleshooting steps:
```bash
# Check the endpoints in the app namespace
kubectl get ep -n app

```

Potential fixes:
1. Fix the selector in the service:
   ```bash
   kubectl edit service nice-app -n app
   ```
2. Fix the selector:
   ```bash
   selector:
     app: nice-app
   ```

## Question 3: Create a Pod named 'health-pod' in namespace 'workloads' using 'nginx' image with a liveness probe that checks the path /healthz on port 80 every 15 seconds, and a readiness probe that checks port 80 every 10 seconds

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

## Question 4: Deploy the Bitnami Nginx chart in the 'web' namespace using Helm

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
