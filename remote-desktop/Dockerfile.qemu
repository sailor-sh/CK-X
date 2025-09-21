# Base Image (x86_64 build only)
FROM nishanb/ck-x-simulator-vnc-base:v3

# --- Add QEMU for ARM emulation ---
# This lets the container run on ARM hosts even if the base image is amd64
COPY --from=multiarch/qemu-user-static:latest /usr/bin/qemu-* /usr/bin/

# Switch to root user for installations
USER 0

# Update and install required dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    ssh-client \
    telnet \
    nano \
    vim \
    xclip \
 && rm -rf /var/lib/apt/lists/*

# create candidate user
RUN useradd -m candidate

# set hostname as terminal
RUN echo "export HOSTNAME=terminal" >> /headless/.bashrc
# set terminal to bash
RUN echo "export TERM=xterm" >> /headless/.bashrc

# when shell opens, switch to candidate user
RUN echo "cd /home/candidate && su candidate" >> /headless/.bashrc

# disable asking for ssh host verification
RUN mkdir -p /home/candidate/.ssh && \
    echo "StrictHostKeyChecking no" >> /home/candidate/.ssh/config && \
    echo "UserKnownHostsFile /dev/null" >> /home/candidate/.ssh/config

# Copy startup script
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Copy agent
COPY agent.py /tmp/agent.py

# Inject startup script into vnc_startup.sh
RUN sed -i '/### every exit != 0 fails the script/a /usr/local/bin/startup.sh' /dockerstartup/vnc_startup.sh
