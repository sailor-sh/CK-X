#!/usr/bin/env bash
set -euo pipefail
img=$(kubectl -n rollout get deploy api-new-c32 -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
[ -n "$img" ] && [[ "$img" != *":does-not-exist" ]]
