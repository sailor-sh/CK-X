#!/bin/bash

# Log startup
echo "Starting CKAD VNC service at $(date)"

echo "echo 'Use Ctrl + Shift + C for copying and Ctrl + Shift + V for pasting'" >> /home/candidate/.bashrc
echo "alias kubectl='echo \"kubectl not available here. Solve this question on the specified instance\"'" >> /home/candidate/.bashrc

# Kill any browser that might be auto-launched by base image
# Run in background loop to catch delayed browser launches
(
    sleep 3
    pkill -f chromium 2>/dev/null || true
    pkill -f chrome 2>/dev/null || true
    pkill -f firefox 2>/dev/null || true
    sleep 2
    pkill -f chromium 2>/dev/null || true
    pkill -f chrome 2>/dev/null || true
    pkill -f firefox 2>/dev/null || true
    # Open terminal instead
    DISPLAY=:1 xfce4-terminal --maximize &
) &

# Run in the background - don't block the main container startup
python3 /tmp/agent.py &

exit 0 