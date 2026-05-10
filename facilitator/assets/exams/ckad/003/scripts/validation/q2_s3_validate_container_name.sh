#!/usr/bin/env bash
set -euo pipefail
name=$(kubectl -n single-pod get pod pod1 -o jsonpath='{.spec.containers[0].name}')
test "$name" = "pod1-container"
