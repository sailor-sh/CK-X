#!/usr/bin/env bash
set -euo pipefail

# Create all namespaces used by ckad-003 (scaffold)
create_ns() {
  local ns="$1"
  if kubectl get ns "$ns" >/dev/null 2>&1; then
    echo "NS $ns already exists"
  else
    kubectl create ns "$ns"
    echo "Created $ns"
  fi
}

for i in $(seq -w 01 22); do
  create_ns "ckad-q${i}"
done

for p in p1 p2 p3; do
  create_ns "ckad-${p}"
done

# Special for Q7 (move across namespaces)
create_ns "ckad-q07-source"
create_ns "ckad-q07-target"

echo "All exam3 namespaces ensured."
