#!/bin/bash
# Q20.03 - HPA targets correct deployment
# Points: 2

TARGET=$(kubectl get hpa app-hpa -n q20 -o jsonpath='{.spec.scaleTargetRef.name}' 2>/dev/null)
[[ "$TARGET" == "scalable-app" ]] && {
  echo "✓ HPA targets scalable-app"
  exit 0
} || {
  echo "✗ Target is $TARGET, expected scalable-app"
  exit 1
}
