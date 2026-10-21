#!/usr/bin/env bash
set -euo pipefail
# Do not pre-create namespace; user must create it
mkdir -p /opt/course/exam3/q02

# Ensure the status command script is NOT pre-created
rm -f /opt/course/exam3/q02/pod1-status-command.sh || true
