#!/bin/bash
# Q18.4 - Service has endpoints
# Points: 2

kubectl get endpoints web-service -n services-clusterip --no-headers 2>/dev/null | grep -q '[0-9]' && {
  echo "✓ Service has endpoints"
  exit 0
} || {
  echo "✗ Service missing endpoints"
  exit 1
}
