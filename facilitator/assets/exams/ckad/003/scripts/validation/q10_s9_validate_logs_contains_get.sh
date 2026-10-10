#!/usr/bin/env bash
set -euo pipefail
# Expect nginx access log line for curl request, e.g., contains GET /
grep -qE 'GET /( |HTTP/)' /opt/course/exam3/q10/service_test.log

