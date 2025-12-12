#!/bin/bash
# Q17.01 - Job exists
# Points: 2

kubectl get job compute-job -n q17 >/dev/null 2>&1 && {
  echo "✓ Job compute-job exists"
  exit 0
} || {
  echo "✗ Job not found"
  exit 1
}
