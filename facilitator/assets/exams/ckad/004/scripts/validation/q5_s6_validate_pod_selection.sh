#!/bin/bash
# Q05.06 - Pods can be selected by labels
# Points: 2

POD_A=$(kubectl get pods -n labels-selectors -l app=web --no-headers 2>/dev/null | wc -l)
POD_B=$(kubectl get pods -n labels-selectors -l app=api --no-headers 2>/dev/null | wc -l)
[[ $POD_A -eq 1 && $POD_B -eq 1 ]] && {
  echo "✓ Pods can be selected by labels"
  exit 0
} || {
  echo "✗ Pod selection issue (web: $POD_A, api: $POD_B)"
  exit 1
}
