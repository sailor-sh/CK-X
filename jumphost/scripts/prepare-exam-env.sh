#!/bin/bash
exec >> /proc/1/fd/1 2>&1


# Log function with timestamp
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Set defaults
NUMBER_OF_NODES=${1:-1}
EXAM_ID=${2:-""}

echo "Exam ID: $EXAM_ID"
echo "Number of nodes: $NUMBER_OF_NODES"

#check docker is running
if ! docker info > /dev/null 2>&1; then
  log "Docker is not running"
  log "Attempting to start docker"
  dockerd &
  sleep 5
  #check docker is running 3 times with 5 second interval
  for i in {1..3}; do
    if docker info > /dev/null 2>&1; then
      log "Docker started successfully"
      break
    fi
    log "Docker failed to start, retrying..."
    sleep 5
  done
fi

log "Starting exam environment preparation with $NUMBER_OF_NODES node(s)"

# Validate input
if ! [[ "$NUMBER_OF_NODES" =~ ^[0-9]+$ ]]; then
  log "ERROR: Number of nodes must be a positive integer"
  exit 1
fi

# Setup kind cluster
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null candidate@k8s-api-server "env-setup $NUMBER_OF_NODES $CLUSTER_NAME"

#Pull assets from URL
curl facilitator:3000/api/v1/exams/$EXAM_ID/assets -o assets.tar.gz

mkdir -p /tmp/exam-assets
#Unzip assets
tar -xzvf assets.tar.gz -C /tmp/exam-assets    

#Remove assets.tar.gz
rm assets.tar.gz

#make every file in /tmp/exam-assets executable
find /tmp/exam-assets -type f -exec chmod +x {} \;

echo "Exam assets downloaded and prepared successfully" 

export KUBECONFIG=/home/candidate/.kube/kubeconfig
echo "Using KUBECONFIG=$KUBECONFIG"

# Ensure kubeconfig exists; if missing, try to fetch from k8s-api-server
if [ ! -f "$KUBECONFIG" ]; then
  echo "KUBECONFIG not found; attempting to copy from k8s-api-server..."
  mkdir -p /home/candidate/.kube
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null candidate@k8s-api-server:/home/candidate/.kube/kubeconfig "$KUBECONFIG" || true
fi

sleep 5

# Wait until API server responds, but don't hang indefinitely (timeout ~2 min)
attempt=0
until kubectl get nodes >/dev/null 2>&1; do
  attempt=$((attempt+1))
  if [ "$attempt" -ge 24 ]; then
    echo "Timed out waiting for API server; proceeding with setup scripts anyway"
    break
  fi
  sleep 5
done

if kubectl get nodes >/dev/null 2>&1; then
  echo "API server is ready"
else
  echo "API server may not be ready; continuing"
fi

# Run setup scripts
for script in /tmp/exam-assets/scripts/setup/q*_setup.sh; do echo "Running $script"; $script || true; done

log "Exam environment preparation completed successfully"
exit 0 
