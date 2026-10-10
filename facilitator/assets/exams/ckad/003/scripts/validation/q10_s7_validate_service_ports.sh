#!/usr/bin/env bash
set -euo pipefail
# validate type ClusterIP and port mapping 3333 -> 80
ns=services-curl
svc=project-plt-6cc-svc

type=$(kubectl -n "$ns" get svc "$svc" -o jsonpath='{.spec.type}')
port=$(kubectl -n "$ns" get svc "$svc" -o jsonpath='{.spec.ports[0].port}')
targetPort=$(kubectl -n "$ns" get svc "$svc" -o jsonpath='{.spec.ports[0].targetPort}')

test "$type" = "ClusterIP"
test "$port" = "3333"

# Accept numeric 80 or a named targetPort that resolves to endpoint port 80
if [ "$targetPort" = "80" ]; then
  exit 0
fi

# Fallback: verify the Service endpoints expose port 80 (covers named targetPort)
ep_port=$(kubectl -n "$ns" get endpoints "$svc" -o jsonpath='{.subsets[0].ports[0].port}' 2>/dev/null || true)
if [ -n "${ep_port:-}" ] && [ "$ep_port" = "80" ]; then
  exit 0
fi

echo "Service targetPort is '$targetPort', endpoints port '$ep_port' (expected 80)" >&2
exit 1
