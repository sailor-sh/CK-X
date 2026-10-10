#!/usr/bin/env bash
set -euo pipefail

# Namespace isolation (optional for Q1)
kubectl get ns ns-list >/dev/null 2>&1 || kubectl create ns ns-list

mkdir -p /opt/course/exam3/q01

# Ensure the expected output file is NOT pre-created
rm -f /opt/course/exam3/q01/namespaces || true
