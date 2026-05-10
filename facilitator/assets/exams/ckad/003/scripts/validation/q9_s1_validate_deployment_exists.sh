#!/usr/bin/env bash
set -euo pipefail
kubectl -n convert-to-deploy get deploy holy-api -o name >/dev/null
