#!/usr/bin/env bash
set -euo pipefail
kubectl get ns jobs >/dev/null 2>&1 || kubectl create ns jobs
mkdir -p /opt/course/exam3/q03

# Ensure the job manifest file is NOT pre-created
rm -f /opt/course/exam3/q03/job.yaml || true
