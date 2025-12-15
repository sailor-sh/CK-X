#!/bin/bash
# Q18.03 - Service endpoints populated
# Points: 4

NS="services-clusterip"
COUNT=$(kubectl get endpoints web-svc -n "$NS" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')
if [ -n "$COUNT" ] && [ "$COUNT" -ge 1 ] 2>/dev/null; then
  echo "✓ Service endpoints populated ($COUNT)"
  exit 0
else
  echo "✗ No endpoints found for service web-svc"
  exit 1
fi

