#!/usr/bin/env bash
set -euo pipefail
kubectl get storageclass moon-retain >/dev/null 2>&1

