#!/usr/bin/env bash
set -euo pipefail

# Global initialization for ckad-003

create_ns() {
  local ns="$1"
  kubectl get ns "$ns" >/dev/null 2>&1 || kubectl create ns "$ns"
}

# Create question namespaces
for i in $(seq -w 01 22); do
  create_ns "ckad-q${i}"
done

# Create preview namespaces
for p in p1 p2 p3; do
  create_ns "ckad-${p}"
done

# Special namespaces for Q7
create_ns "ckad-q07-source"
create_ns "ckad-q07-target"

# Create output directories
mkdir -p /opt/course/exam3
for i in $(seq -w 01 22); do
  mkdir -p "/opt/course/exam3/q${i}"
done
mkdir -p /opt/course/exam3/p1 /opt/course/exam3/p2 /opt/course/exam3/p3

echo "ckad-003 global setup complete"
