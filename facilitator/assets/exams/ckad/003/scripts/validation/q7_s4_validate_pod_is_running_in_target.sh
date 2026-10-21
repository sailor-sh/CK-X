#!/usr/bin/env bash
set -euo pipefail
# This script validates that the pod in the target namespace is in a Running state and is Ready.
kubectl -n pod-move-target get pod webserver-sat-003 -o jsonpath='{.status.phase}' | grep -q 'Running'
kubectl -n pod-move-target get pod webserver-sat-003 -o jsonpath='{.status.containerStatuses[0].ready}' | grep -q 'true'
