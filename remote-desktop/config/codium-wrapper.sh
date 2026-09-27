#!/bin/bash
# VSCodium launcher for the CK-X remote desktop.
#
# The desktop session itself runs as root, but the editor must not: Electron
# shows a "running as root is not recommended" banner with [Superuser] in the
# title bar, and everything the editor and its integrated terminal touch ends
# up owned by uid 0. Drop to the exam user instead.
#
# The candidate reaches X through the `xhost +SI:localuser:candidate` grant that
# startup.sh installs, so the root-owned .Xauthority is dropped on the way down
# rather than inherited and failed on.
if [ "$(id -u)" = "0" ]; then
  exec env -u XAUTHORITY HOME=/home/candidate \
    runuser -u candidate -- "$0" "$@"
fi

# --no-sandbox is still needed as an unprivileged user: chrome-sandbox is setuid
# here, but the container's seccomp profile blocks the namespace sandbox the
# zygote needs, and Electron exits without a window instead of falling back.
# No GPU behind Xvnc, and /dev/shm is small in a container.
exec /usr/bin/codium \
  --no-sandbox \
  --disable-gpu \
  --disable-dev-shm-usage \
  --user-data-dir="${HOME:-/home/candidate}/.vscodium-data" \
  "$@"
