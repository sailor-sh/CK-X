#!/usr/bin/env bash
set -euo pipefail
kubectl get sc moon-retain -o name >/dev/null

