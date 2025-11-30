#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q07-target get pod webserver-sat-003 >/dev/null 2>&1

