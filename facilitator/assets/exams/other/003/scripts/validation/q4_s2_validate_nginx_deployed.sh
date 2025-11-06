#!/bin/bash
# Validate that Bitnami Nginx is deployed with 2 replicas and LoadBalancer service type in namespace 'web'

NAMESPACE="web"
RELEASE_NAME="nginx"  # Default release name, can also check for any Nginx release

# Check if the namespace exists
kubectl get namespace $NAMESPACE > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Namespace '$NAMESPACE' not found"
  exit 1
fi

# Check if there's any nginx deployment from Helm in the namespace
HELM_RELEASE=$(helm list -n $NAMESPACE 2>/dev/null | grep -i nginx | wc -l)
if [ $HELM_RELEASE -eq 0 ]; then
  echo "❌ No Nginx Helm release found in namespace '$NAMESPACE'"
  exit 1
fi

echo "✅ Nginx Helm release found in namespace '$NAMESPACE'"

# Find the deployment name (may vary based on release name)
DEPLOYMENT_NAME=$(kubectl get deployments -n $NAMESPACE -l "app.kubernetes.io/name=nginx" -o name 2>/dev/null || kubectl get deployments -n $NAMESPACE -l "app=nginx" -o name 2>/dev/null)

if [ -z "$DEPLOYMENT_NAME" ]; then
  echo "❌ Cannot find Nginx deployment in namespace '$NAMESPACE'"
  exit 1
fi

DEPLOYMENT_NAME=$(echo $DEPLOYMENT_NAME | sed 's|deployment.apps/||')
echo "✅ Found Nginx deployment: $DEPLOYMENT_NAME"

# Check replicas count
REPLICAS=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>/dev/null)

if [ -z "$REPLICAS" ]; then
  echo "❌ Cannot get replica count for deployment '$DEPLOYMENT_NAME'"
  exit 1
fi

if [ "$REPLICAS" -ne 2 ]; then
  echo "❌ Deployment '$DEPLOYMENT_NAME' has $REPLICAS replicas, but 2 were required"
  exit 1
fi

echo "✅ Deployment has correct number of replicas: $REPLICAS"

# Check service type
SERVICE_NAME=$(kubectl get services -n $NAMESPACE -l "app.kubernetes.io/name=nginx" -o name 2>/dev/null || kubectl get services -n $NAMESPACE -l "app=nginx" -o name 2>/dev/null)

if [ -z "$SERVICE_NAME" ]; then
  echo "❌ Cannot find Nginx service in namespace '$NAMESPACE'"
  exit 1
fi

SERVICE_NAME=$(echo $SERVICE_NAME | sed 's|service/||')
SERVICE_TYPE=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.type}' 2>/dev/null)

if [ -z "$SERVICE_TYPE" ]; then
  echo "❌ Cannot get service type for service '$SERVICE_NAME'"
  exit 1
fi

if [ "$SERVICE_TYPE" != "LoadBalancer" ]; then
  echo "❌ Service '$SERVICE_NAME' is of type '$SERVICE_TYPE', but 'LoadBalancer' was required"
  exit 1
fi

echo "✅ Service has correct type: $SERVICE_TYPE"

# Check if pods are running
RUNNING_PODS=$(kubectl get pods -n $NAMESPACE -l "app.kubernetes.io/name=nginx" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' 2>/dev/null | wc -w)

if [ -z "$RUNNING_PODS" ] || [ "$RUNNING_PODS" -eq 0 ]; then
  # Try another common label
  RUNNING_PODS=$(kubectl get pods -n $NAMESPACE -l "app=nginx" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' 2>/dev/null | wc -w)
fi

if [ -z "$RUNNING_PODS" ] || [ "$RUNNING_PODS" -lt "$REPLICAS" ]; then
  echo "❌ Not all Nginx pods are running (running: $RUNNING_PODS, expected: $REPLICAS)"
  exit 1
fi

echo "✅ All $RUNNING_PODS Nginx pods are running"
echo "✅ Bitnami Nginx has been successfully deployed with 2 replicas and LoadBalancer service"
exit 0 