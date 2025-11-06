#!/bin/bash
# Validate that the Bitnami repository is added to Helm

# Check if the Bitnami repository is added
BITNAMI_REPO=$(helm repo list 2>/dev/null | grep -i bitnami)
if [ $? -ne 0 ] || [ -z "$BITNAMI_REPO" ]; then
  echo "❌ Bitnami repository is not added to Helm"
  exit 1
fi

# Extract the URL from the repo list
REPO_URL=$(echo "$BITNAMI_REPO" | awk '{print $2}')

# Check if the URL is correct
if [[ ! "$REPO_URL" =~ "charts.bitnami.com/bitnami" ]]; then
  echo "❌ Bitnami repository URL is incorrect: $REPO_URL"
  exit 1
fi

echo "✅ Bitnami repository is properly configured with URL: $REPO_URL"

# Check if repo is up to date
LAST_UPDATE=$(helm repo list 2>/dev/null | grep -i bitnami | awk '{print $3}')
if [ -n "$LAST_UPDATE" ]; then
  echo "ℹ️  Last repository update: $LAST_UPDATE"
fi

exit 0 