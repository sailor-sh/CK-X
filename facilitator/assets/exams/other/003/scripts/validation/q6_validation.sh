#!/bin/bash
set -e

# Validation for Question 6: CI/CD Pipeline Integration
echo "Validating CI/CD Pipeline Integration scenario..."

# Check if cicd namespace exists
if ! kubectl get namespace cicd &> /dev/null; then
    echo "FAIL: Namespace 'cicd' not found"
    exit 1
fi

# Check if Jenkins deployment exists
if ! kubectl get deployment jenkins -n cicd &> /dev/null; then
    echo "FAIL: Deployment 'jenkins' not found in namespace cicd"
    exit 1
fi

# Check if ArgoCD deployment exists
if ! kubectl get deployment argocd-server -n cicd &> /dev/null; then
    echo "FAIL: Deployment 'argocd-server' not found in namespace cicd"
    exit 1
fi

# Check if GitLab Runner deployment exists
if ! kubectl get deployment gitlab-runner -n cicd &> /dev/null; then
    echo "FAIL: Deployment 'gitlab-runner' not found in namespace cicd"
    exit 1
fi

# Check Jenkins readiness
JENKINS_READY=$(kubectl get deployment jenkins -n cicd -o jsonpath='{.status.readyReplicas}')
if [ "$JENKINS_READY" != "1" ]; then
    echo "FAIL: Jenkins should have 1 ready replica, found: $JENKINS_READY"
    exit 1
fi

# Check ArgoCD readiness
ARGOCD_READY=$(kubectl get deployment argocd-server -n cicd -o jsonpath='{.status.readyReplicas}')
if [ "$ARGOCD_READY" != "1" ]; then
    echo "FAIL: ArgoCD Server should have 1 ready replica, found: $ARGOCD_READY"
    exit 1
fi

# Check GitLab Runner readiness
GITLAB_RUNNER_READY=$(kubectl get deployment gitlab-runner -n cicd -o jsonpath='{.status.readyReplicas}')
if [ "$GITLAB_RUNNER_READY" != "2" ]; then
    echo "FAIL: GitLab Runner should have 2 ready replicas, found: $GITLAB_RUNNER_READY"
    exit 1
fi

# Check if services exist
REQUIRED_SERVICES=("jenkins-service" "argocd-server-service" "gitlab-runner-service")
for svc in "${REQUIRED_SERVICES[@]}"; do
    if ! kubectl get service "$svc" -n cicd &> /dev/null; then
        echo "FAIL: Service '$svc' not found in namespace cicd"
        exit 1
    fi
done

# Check if PVC exists for Jenkins data
if ! kubectl get pvc jenkins-data -n cicd &> /dev/null; then
    echo "FAIL: PVC 'jenkins-data' not found in namespace cicd"
    exit 1
fi

# Check if ConfigMaps exist for pipeline configuration
REQUIRED_CONFIGMAPS=("jenkins-config" "argocd-config" "pipeline-scripts")
for cm in "${REQUIRED_CONFIGMAPS[@]}"; do
    if ! kubectl get configmap "$cm" -n cicd &> /dev/null; then
        echo "FAIL: ConfigMap '$cm' not found in namespace cicd"
        exit 1
    fi
done

# Check if Secrets exist for CI/CD credentials
REQUIRED_SECRETS=("jenkins-secrets" "argocd-secrets" "docker-registry-secret")
for secret in "${REQUIRED_SECRETS[@]}"; do
    if ! kubectl get secret "$secret" -n cicd &> /dev/null; then
        echo "FAIL: Secret '$secret' not found in namespace cicd"
        exit 1
    fi
done

# Check if ServiceAccount exists for CI/CD operations
if ! kubectl get serviceaccount cicd-sa -n cicd &> /dev/null; then
    echo "FAIL: ServiceAccount 'cicd-sa' not found in namespace cicd"
    exit 1
fi

# Check if ClusterRoleBinding exists for CI/CD permissions
if ! kubectl get clusterrolebinding cicd-binding &> /dev/null; then
    echo "FAIL: ClusterRoleBinding 'cicd-binding' not found"
    exit 1
fi

# Check if ArgoCD Application exists for GitOps
if ! kubectl get application microservices-app -n cicd &> /dev/null; then
    echo "WARN: ArgoCD Application 'microservices-app' not found (may not be configured yet)"
fi

echo "PASS: CI/CD Pipeline Integration validation successful"
