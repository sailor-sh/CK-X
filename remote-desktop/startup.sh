#!/bin/bash

# Log startup
echo "Starting CKAD VNC service at $(date)"

echo "echo 'Use Ctrl + Shift + C for copying and Ctrl + Shift + V for pasting'" >> /home/candidate/.bashrc
echo "alias kubectl='echo \"kubectl not available here. Solve this question on the specified instance\"'" >> /home/candidate/.bashrc

# The desktop session runs as root, so X rejects clients running as candidate:
# anything started from the candidate shell (e.g. `code manifest.yaml`), and
# VSCodium itself, which drops to candidate. Grant access once X is up.
(
  for _ in $(seq 1 60); do
    if [ -S /tmp/.X11-unix/X1 ] && DISPLAY=:1 xhost +SI:localuser:candidate >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
) &

# Run in the background - don't block the main container startup
python3 /tmp/agent.py &

exit 0 