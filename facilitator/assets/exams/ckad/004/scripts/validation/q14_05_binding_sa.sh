#!/bin/bash
# Q14.05 - Binding references correct SA
# Points: 2

SA=$(kubectl get rolebinding app-rolebinding -n q14 -o jsonpath='{.subjects[0].name}' 2>/dev/null)
[[ "$SA" == "app-sa" ]] && {
  echo "✓ Binding references app-sa"
  exit 0
} || {
  echo "✗ Binding references $SA, expected app-sa"
  exit 1
}
