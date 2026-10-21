#!/usr/bin/env bash
set -euo pipefail

TOKEN_FILE="/opt/course/exam3/q05/token"
NAMESPACE="service-accounts"
SA_NAME="neptune-sa-v2"
EXPECTED_WHOAMI="system:serviceaccount:${NAMESPACE}:${SA_NAME}"

# Fail if the token file is missing or empty.
if [ ! -s "$TOKEN_FILE" ]; then
  exit 1
fi

TOKEN=$(tr -d '\n\r' < "$TOKEN_FILE")
# Require valid JWT format
if ! [[ "$TOKEN" =~ ^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$ ]]; then
  exit 1
fi

# Prefer kubectl whoami, fallback to kubectl auth whoami, finally to decoding 'sub'.
WHOAMI_RESULT=""

# 1) Try kubectl whoami (prints just the username)
if kubectl whoami --help >/dev/null 2>&1; then
  OUT=$(kubectl whoami --token="$TOKEN" 2>/dev/null || true)
  if [ -n "$OUT" ]; then
    WHOAMI_RESULT="$OUT"
  fi
fi

# 2) Try kubectl auth whoami -o json, extract user.username
if [ -z "$WHOAMI_RESULT" ]; then
  OUT_JSON=$(kubectl auth whoami --token="$TOKEN" -o json 2>/dev/null || true)
  if [ -n "$OUT_JSON" ]; then
    if command -v jq >/dev/null 2>&1; then
      WHOAMI_RESULT=$(printf '%s' "$OUT_JSON" | jq -r '.user.username // empty')
    elif command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
      PY=python3; command -v python >/dev/null 2>&1 && PY=python
      WHOAMI_RESULT=$($PY - << 'PY'
import json,sys
try:
  data=json.load(sys.stdin)
  user=data.get("user",{})
  print(user.get("username",""))
except Exception:
  print("")
PY
      <<< "$OUT_JSON")
    else
      WHOAMI_RESULT=$(echo "$OUT_JSON" | grep -o '"username":"[^"]*' | head -n1 | cut -d'"' -f4)
    fi
  fi
fi

# 3) Try kubectl auth whoami (human output), parse the User line
if [ -z "$WHOAMI_RESULT" ]; then
  OUT_TEXT=$(kubectl auth whoami --token="$TOKEN" 2>/dev/null || true)
  if [ -n "$OUT_TEXT" ]; then
    WHOAMI_RESULT=$(printf '%s' "$OUT_TEXT" | awk '/^User:/{print substr($0, index($0,$2))} /^Username:/{print substr($0, index($0,$2))}' | head -n1)
    # Fallback: loose grep for a typical identity
    if [ -z "$WHOAMI_RESULT" ]; then
      WHOAMI_RESULT=$(printf '%s' "$OUT_TEXT" | grep -Eo 'system:serviceaccount:[a-z0-9-]+:[A-Za-z0-9_.-]+' | head -n1 || true)
    fi
  fi
fi

# 4) Fallback: decode JWT 'sub' claim
if [ -z "$WHOAMI_RESULT" ]; then
  PAYLOAD=$(printf '%s' "$TOKEN" | cut -d'.' -f2)
  input="${PAYLOAD//-/+}"
  input="${input//_//}"
  pad=$(( (4 - ${#input} % 4) % 4 ))
  for i in $(seq 1 $pad); do input="${input}="; done
  DECODED=$(printf '%s' "$input" | base64 -d 2>/dev/null || true)
  if command -v jq >/dev/null 2>&1; then
    WHOAMI_RESULT=$(printf '%s' "$DECODED" | jq -r '.sub // empty')
  elif command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
    PY=python3; command -v python >/dev/null 2>&1 && PY=python
    WHOAMI_RESULT=$($PY - << 'PY'
import json,sys
try:
  data=json.load(sys.stdin)
  print(data.get("sub",""))
except Exception:
  print("")
PY
    <<< "$DECODED")
  else
    WHOAMI_RESULT=$(echo "$DECODED" | grep -o '"sub":"[^"]*' | cut -d'"' -f4)
  fi
fi

if [[ "$WHOAMI_RESULT" == "$EXPECTED_WHOAMI" ]]; then
  exit 0
fi

exit 1
