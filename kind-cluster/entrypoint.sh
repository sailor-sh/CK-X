#!/bin/sh

# ===============================================================================
#   KIND Cluster Setup Entrypoint Script
#   Purpose: Initialize Docker and create Kind cluster
# ===============================================================================

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== INITIALIZATION STARTED ====="
echo "$(date '+%Y-%m-%d %H:%M:%S') | Executing container startup script..."

# Execute current entrypoint 
sh /usr/local/bin/startup.sh &

# ===============================================================================
#   Docker Readiness Check
# ===============================================================================

echo "$(date '+%Y-%m-%d %H:%M:%S') | Checking Docker service status..."
DOCKER_CHECK_COUNT=0

# Wait for docker to be ready
while ! docker ps; do   
    DOCKER_CHECK_COUNT=$((DOCKER_CHECK_COUNT+1))
    echo "$(date '+%Y-%m-%d %H:%M:%S') | [WAITING] Docker service not ready yet... (attempt $DOCKER_CHECK_COUNT)"
    sleep 5
done

echo "$(date '+%Y-%m-%d %H:%M:%S') | [SUCCESS] Docker service is ready and operational"

#pull kindest/node image
docker pull kindest/node:$KIND_DEFAULT_VERSION

#add user for ssh access
adduser -S -D -H -s /sbin/nologin -G sshd sshd

#start ssh service
/usr/sbin/sshd -D &

sleep 10
touch /ready

# Keep container running
tail -f /dev/null