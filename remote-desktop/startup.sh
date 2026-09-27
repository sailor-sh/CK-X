#!/bin/bash

# Log startup
echo "Starting CKAD VNC service at $(date)"

echo "echo 'Use Ctrl + Shift + C for copying and Ctrl + Shift + V for pasting'" >> /home/candidate/.bashrc
echo "alias kubectl='echo \"kubectl not available here. Solve this question on the specified instance\"'" >> /home/candidate/.bashrc

# Run in the background - don't block the main container startup
python3 /tmp/agent.py &

exit 0 