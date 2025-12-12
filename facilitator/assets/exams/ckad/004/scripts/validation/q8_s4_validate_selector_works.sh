#!/bin/bash
# Q08.04 - Selectors work
# Points: 2

WEB=$(kubectl get pods -n rollbacks -l app=web --no-headers 2>/dev/null | wc -l)
[[ $WEB -gt 0 ]] && {
  echo "✓ Web selector works"
  exit 0
} || {
  echo "✗ No pods with app=web"
  exit 1
}
