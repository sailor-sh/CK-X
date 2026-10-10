#!/usr/bin/env bash
set -euo pipefail

# Accept either:
# 1) Exact ENV line in Dockerfile (strict match), OR
# 2) SUN_CIPHER_ID present in the running container env, OR
# 3) SUN_CIPHER_ID present in the built image env (localhost:5000/sun-cipher:v1-docker)

TARGET_ID="5b9c1065-e39d-4a43-a04a-e59bcea3e03f"
DOCKERFILE="/opt/course/exam3/q11/image/Dockerfile"

pass=false

# Option 1: strict Dockerfile line (backward compatible)
if [[ -f "$DOCKERFILE" ]]; then
  if grep -qE '^ENV[[:space:]]+SUN_CIPHER_ID=5b9c1065-e39d-4a43-a04a-e59bcea3e03f$' "$DOCKERFILE"; then
    pass=true
  else
    # Also allow common variants: space syntax and/or quoted value
    if grep -qE '^ENV[[:space:]]+SUN_CIPHER_ID([[:space:]]+|=)"?5b9c1065-e39d-4a43-a04a-e59bcea3e03f"?$' "$DOCKERFILE"; then
      pass=true
    fi
  fi
fi

# Helper to check env on a docker target (container or image)
check_env_on() {
  local target=$1
  docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$target" 2>/dev/null | grep -qx "SUN_CIPHER_ID=${TARGET_ID}"
}

# Option 2: running container env
if [[ "$pass" = false ]]; then
  if docker ps --format '{{.Names}}' | grep -qx 'sun-cipher'; then
    if check_env_on sun-cipher; then
      pass=true
    fi
  fi
fi

# Option 3: built/pushed image env
if [[ "$pass" = false ]]; then
  if docker images --format '{{.Repository}}:{{.Tag}}' | grep -qx 'localhost:5000/sun-cipher:v1-docker'; then
    if check_env_on localhost:5000/sun-cipher:v1-docker; then
      pass=true
    fi
  fi
fi

if [[ "$pass" = true ]]; then
  exit 0
else
  echo "SUN_CIPHER_ID not found hardcoded or in container/image env" >&2
  exit 1
fi
