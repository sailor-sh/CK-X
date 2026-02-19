#!/usr/bin/env bash
set -euo pipefail
! kubectl -n pod-move-source get pod webserver-sat-003 >/dev/null 2>&1
