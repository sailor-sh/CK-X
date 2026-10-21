#!/usr/bin/env bash
set -euo pipefail

# Namespace and object under test
ns=secrets-cm
name=secret1

# Validate that secret1 contains keys user=test and pass=pwd
# Note: Secret data is base64-encoded in Kubernetes; decode before comparing
u=$(kubectl -n "$ns" get secret "$name" -o jsonpath='{.data.user}' 2>/dev/null | base64 -d 2>/dev/null || true)
p=$(kubectl -n "$ns" get secret "$name" -o jsonpath='{.data.pass}' 2>/dev/null | base64 -d 2>/dev/null || true)

test "$u" = "test" && test "$p" = "pwd"

