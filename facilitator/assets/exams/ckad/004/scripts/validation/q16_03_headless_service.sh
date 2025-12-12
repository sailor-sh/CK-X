#!/bin/bash
# Q16.03 - Service is headless
# Points: 2

IP=$(kubectl get service mysql -n q16 -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
[[ "$IP" == "None" ]] && {
  echo "✓ Service is headless"
  exit 0
} || {
  echo "✗ ClusterIP is $IP, expected None"
  exit 1
}
