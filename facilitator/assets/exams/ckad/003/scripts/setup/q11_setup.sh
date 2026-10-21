#!/usr/bin/env bash
set -euo pipefail
mkdir -p /opt/course/exam3/q11/image /opt/course/exam3/q11

# Ensure local registry at localhost:5000 is running
is_up=0
if command -v curl >/dev/null 2>&1; then
  if curl -fsS http://localhost:5000/v2/ >/dev/null 2>&1; then
    is_up=1
  fi
else
  # Fallback TCP check
  if (exec 3<>/dev/tcp/127.0.0.1/5000) 2>/dev/null; then
    exec 3>&-
    is_up=1
  fi
fi

if [ "$is_up" -ne 1 ]; then
  if command -v docker >/dev/null 2>&1; then
    docker rm -f ckx-registry 2>/dev/null || true
    docker run -d -p 5000:5000 --name ckx-registry registry:2 >/dev/null
  fi
fi

# Seed minimal Dockerfile and Go app (user will modify ENV and build)
cat > /opt/course/exam3/q11/image/Dockerfile <<'EOF'
# build container stage 1
FROM golang:1.21-alpine as build
WORKDIR /src
COPY . .
# Build a static-ish binary for linux
ENV CGO_ENABLED=0 GOOS=linux
RUN go build -a -installsuffix cgo -o /out/app .

# app container stage 2
FROM alpine:3.18
# Student must set this to the required hardcoded value in Step 1
ENV SUN_CIPHER_ID=""
COPY --from=build /out/app /app
CMD ["/app"]
EOF

cat > /opt/course/exam3/q11/image/main.go <<'EOF'
package main
import (
  "fmt"
  "os"
  "time"
)
func main(){
  id := os.Getenv("SUN_CIPHER_ID")
  for { fmt.Printf("SUN_CIPHER_ID=%s\n", id); time.Sleep(2*time.Second) }
}
EOF

# Seed a minimal go.mod to allow module-aware builds
cat > /opt/course/exam3/q11/image/go.mod <<'EOF'
module sun-cipher

go 1.21
EOF
