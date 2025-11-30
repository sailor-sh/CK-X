#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q06 get pod pod6 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q True

