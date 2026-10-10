#!/usr/bin/env bash
set -euo pipefail
ae=$(kubectl -n convert-to-deploy get deploy holy-api -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}' 2>/dev/null || echo "")
pr=$(kubectl -n convert-to-deploy get deploy holy-api -o jsonpath='{.spec.template.spec.containers[0].securityContext.privileged}' 2>/dev/null || echo "")
test "$ae" = "false" && test "$pr" = "false"
