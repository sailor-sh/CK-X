#!/usr/bin/env bash
# Verify CK-X facilitator backend is running and returns JSON.
# Run from repo root: ./scripts/verify-facilitator.sh

set -e
BASE="${1:-http://localhost:30080}"

echo "=== Checking Docker containers ==="
docker-compose ps 2>/dev/null || docker compose ps 2>/dev/null || echo "Warning: docker-compose not run (containers may be up anyway)"

echo ""
echo "=== 1. Nginx reachable at $BASE ==="
code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/" || true)
if [ "$code" = "200" ] || [ "$code" = "302" ]; then
  echo "OK (HTTP $code)"
else
  echo "FAIL (HTTP $code). Is nginx running? Start with: docker-compose up -d"
fi

echo ""
echo "=== 2. Facilitator health (JSON) ==="
health="$BASE/facilitator/health"
resp=$(curl -s -w "\n%{http_code}" "$health" 2>/dev/null || true)
code=$(echo "$resp" | tail -n1)
body=$(echo "$resp" | sed '$d')
if [ "$code" = "200" ]; then
  if echo "$body" | grep -q '"status"'; then
    echo "OK (HTTP 200, JSON): $body"
  else
    echo "WARN (HTTP 200 but not JSON): $body"
  fi
else
  echo "FAIL (HTTP $code). Is facilitator container running? body: $body"
fi

echo ""
echo "=== 3. Facilitator API /assements/ (JSON array) ==="
assements="$BASE/facilitator/api/v1/assements/"
resp=$(curl -s -w "\n%{http_code}" "$assements" 2>/dev/null || true)
code=$(echo "$resp" | tail -n1)
body=$(echo "$resp" | sed '$d')
if [ "$code" = "200" ]; then
  if echo "$body" | grep -q '^\[' || echo "$body" | grep -q '"labs"'; then
    echo "OK (HTTP 200, JSON). Labs count: $(echo "$body" | grep -o '"id"' | wc -l)"
  else
    echo "WARN (HTTP 200 but unexpected body): ${body:0:120}..."
  fi
else
  echo "FAIL (HTTP $code). body: ${body:0:200}"
fi

echo ""
echo "=== 4. Facilitator API /exams/current (JSON or 404) ==="
current="$BASE/facilitator/api/v1/exams/current"
resp=$(curl -s -w "\n%{http_code}" "$current" 2>/dev/null || true)
code=$(echo "$resp" | tail -n1)
body=$(echo "$resp" | sed '$d')
if [ "$code" = "200" ] || [ "$code" = "404" ]; then
  if echo "$body" | grep -qE '^\{|^\[|"message"|"error"'; then
    echo "OK (HTTP $code, JSON)"
  else
    echo "WARN (HTTP $code but not JSON): ${body:0:80}..."
  fi
else
  echo "FAIL (HTTP $code). body: ${body:0:200}"
fi

echo ""
echo "Done. If all OK, Sailor API (FACILITATOR_BASE_URL=$BASE) can proxy to facilitator."
