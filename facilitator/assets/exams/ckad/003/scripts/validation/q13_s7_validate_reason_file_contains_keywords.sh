#!/usr/bin/env bash
set -euo pipefail

file=/opt/course/exam3/q13/pvc-126-reason

test -s "$file"

# Look for strong hints that the message is from PVC events about missing external provisioner
# Accept any of these robust patterns across k8s versions
grep -Eiq 'external provisioner|provisioner[^\n]*moon-retainer|moon-retainer' "$file"

