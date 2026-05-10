#!/usr/bin/env bash
set -euo pipefail
ns=secrets-cm
name=secret-handler
env1=$(kubectl -n "$ns" get pod "$name" -o jsonpath='{.spec.containers[0].env[?(@.name=="SECRET1_USER")].valueFrom.secretKeyRef.name}')
key1=$(kubectl -n "$ns" get pod "$name" -o jsonpath='{.spec.containers[0].env[?(@.name=="SECRET1_USER")].valueFrom.secretKeyRef.key}')
env2=$(kubectl -n "$ns" get pod "$name" -o jsonpath='{.spec.containers[0].env[?(@.name=="SECRET1_PASS")].valueFrom.secretKeyRef.name}')
key2=$(kubectl -n "$ns" get pod "$name" -o jsonpath='{.spec.containers[0].env[?(@.name=="SECRET1_PASS")].valueFrom.secretKeyRef.key}')
test "$env1" = "secret1" && test "$key1" = "user" && test "$env2" = "secret1" && test "$key2" = "pass"
