#!/bin/bash
# VSCodium launcher for the CK-X remote desktop.
# The VNC session runs as root, so Electron needs --no-sandbox plus an explicit
# user data dir, and there is no GPU behind Xvnc.
exec /usr/bin/codium \
  --no-sandbox \
  --disable-gpu \
  --disable-dev-shm-usage \
  --user-data-dir="${HOME:-/root}/.vscodium-data" \
  "$@"
