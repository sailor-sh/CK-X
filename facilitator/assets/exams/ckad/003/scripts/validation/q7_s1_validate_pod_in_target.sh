#!/usr/bin/env bash
set -euo pipefail
kubectl -n pod-move-target get pod webserver-sat-003 -o name >/dev/null
