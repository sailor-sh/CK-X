#!/usr/bin/env bash
set -euo pipefail

TOKEN_FILE="/opt/course/exam3/q05/token"
NAMESPACE="service-accounts"
SA_NAME="neptune-sa-v2"
EXPECTED_SUB="system:serviceaccount:${NAMESPACE}:${SA_NAME}"

# Fail if token file is missing or empty
if [ ! -s "$TOKEN_FILE" ]; then
  exit 1
fi

TOKEN=$(tr -d '\n\r' < "$TOKEN_FILE")
# Require valid JWT format
if ! [[ "$TOKEN" =~ ^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$ ]]; then
  exit 1
fi

# Base64url decode helper (no padding, -_/ alphabet)
b64url_decode() {
  local input="$1"
  input="${input//-/+}"
  input="${input//_//}"
  local pad=$(( (4 - ${#input} % 4) % 4 ))
  printf '%s' "$input" | awk -v p="$pad" '{ for(i=0;i<p;i++) $0=$0"="; print }' | base64 -d 2>/dev/null || true
}

PAYLOAD=$(printf '%s' "$TOKEN" | cut -d'.' -f2)
DECODED_PAYLOAD=$(b64url_decode "$PAYLOAD")

# If decode failed, fail
if [ -z "$DECODED_PAYLOAD" ]; then
  exit 1
fi

SA_FROM_CLAIM=""
NS_FROM_CLAIM=""
SUB=""

if command -v jq >/dev/null 2>&1; then
  SA_FROM_CLAIM=$(printf '%s' "$DECODED_PAYLOAD" | jq -r '."kubernetes.io/serviceaccount/service-account.name" // empty')
  NS_FROM_CLAIM=$(printf '%s' "$DECODED_PAYLOAD" | jq -r '."kubernetes.io/serviceaccount/namespace" // empty')
  SUB=$(printf '%s' "$DECODED_PAYLOAD" | jq -r '.sub // empty')
elif command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
  PY=python3
  command -v python >/dev/null 2>&1 && PY=python
  SA_FROM_CLAIM=$($PY - << 'PY'
import json,sys
try:
  data=json.load(sys.stdin)
  print(data.get("kubernetes.io/serviceaccount/service-account.name",""))
except Exception:
  print("")
PY
  <<< "$DECODED_PAYLOAD")
  NS_FROM_CLAIM=$($PY - << 'PY'
import json,sys
try:
  data=json.load(sys.stdin)
  print(data.get("kubernetes.io/serviceaccount/namespace",""))
except Exception:
  print("")
PY
  <<< "$DECODED_PAYLOAD")
  SUB=$($PY - << 'PY'
import json,sys
try:
  data=json.load(sys.stdin)
  print(data.get("sub",""))
except Exception:
  print("")
PY
  <<< "$DECODED_PAYLOAD")
else
  SA_FROM_CLAIM=$(echo "$DECODED_PAYLOAD" | grep -o '"kubernetes.io/serviceaccount/service-account.name":"[^"]*' | cut -d'"' -f4)
  NS_FROM_CLAIM=$(echo "$DECODED_PAYLOAD" | grep -o '"kubernetes.io/serviceaccount/namespace":"[^"]*' | cut -d'"' -f4)
  SUB=$(echo "$DECODED_PAYLOAD" | grep -o '"sub":"[^"]*' | cut -d'"' -f4)
fi

# Accept either explicit k8s SA claims or matching sub claim
if {
     [ "$SA_FROM_CLAIM" = "$SA_NAME" ] && [ "$NS_FROM_CLAIM" = "$NAMESPACE" ];
   } || [ "$SUB" = "$EXPECTED_SUB" ]; then
  exit 0
fi

exit 1
