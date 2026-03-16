#!/usr/bin/env bash
set -euo pipefail
kubectl -n services-curl get pod project-plt-6cc-api -o jsonpath='{.spec.containers[0].image}' | grep -qx 'nginx:1.17.3-alpine'

