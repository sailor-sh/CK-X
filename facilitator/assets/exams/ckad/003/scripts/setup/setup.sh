#!/usr/bin/env bash
set -euo pipefail
chmod +x scripts/setup/q*_setup.sh
for s in scripts/setup/q*_setup.sh; do echo "Running $s"; $s; done
echo "ckad-003 setup completed"
