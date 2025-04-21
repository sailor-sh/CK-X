#!/bin/bash
set -e

# Check if bitnami repo is added
helm repo list | grep bitnami || {
    echo "Bitnami repository not found in helm repo list"
    exit 1
}

# Check if repo URL is correct
REPO_URL=$(helm repo list | grep bitnami | awk '{print $2}')
if [[ "$REPO_URL" != "https://charts.bitnami.com/bitnami" ]]; then
    echo "Incorrect repository URL. Expected https://charts.bitnami.com/bitnami, got $REPO_URL"
    exit 1
fi

# Check if repo is up to date
helm repo update bitnami || {
    echo "Failed to update bitnami repository"
    exit 1
}

echo "Helm repository validation successful"
exit 0 