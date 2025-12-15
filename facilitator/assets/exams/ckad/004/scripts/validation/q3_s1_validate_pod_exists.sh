#!/bin/bash
# Q03.01 - Pod multi-box exists
# Points: 2

../common/validate_resource_exists.sh pod multi-box multi-container && {
  echo "✓ Pod multi-box exists in multi-container"
  exit 0
} || {
  echo "✗ Pod multi-box not found in multi-container"
  exit 1
}
