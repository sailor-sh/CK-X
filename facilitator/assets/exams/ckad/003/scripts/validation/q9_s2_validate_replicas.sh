#!/usr/bin/env bash
set -euo pipefail
rep=$(kubectl -n convert-to-deploy get deploy holy-api -o jsonpath='{.spec.replicas}')
test "$rep" = "3"
