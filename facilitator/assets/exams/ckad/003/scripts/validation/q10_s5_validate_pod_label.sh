#!/usr/bin/env bash
set -euo pipefail
kubectl -n services-curl get pod project-plt-6cc-api -o jsonpath='{.metadata.labels.project}' | grep -qx 'plt-6cc-api'

