#!/usr/bin/env bash
set -euo pipefail
SRC=ckad-q07-source
TGT=ckad-q07-target
POD=webserver-sat-003
kubectl -n "$TGT" get pod "$POD" >/dev/null 2>&1 || { echo "pod not in target"; exit 1; }
if kubectl -n "$SRC" get pod "$POD" >/dev/null 2>&1; then
  echo "pod still in source"; exit 1;
fi
