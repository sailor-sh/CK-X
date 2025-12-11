#!/bin/bash
set -e

NAMESPACE="q017"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create Job
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: compute-job
  namespace: $NAMESPACE
spec:
  template:
    spec:
      containers:
      - name: compute
        image: busybox:latest
        command: ['sh', '-c', 'echo "Job running"; sleep 10; echo "Job completed"']
      restartPolicy: Never
EOF

# Create CronJob
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: periodic-task
  namespace: $NAMESPACE
spec:
  schedule: "0 0 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: task
            image: busybox:latest
            command: ['sh', '-c', 'echo "Scheduled task running"']
          restartPolicy: OnFailure
EOF

echo "✓ Q017 setup complete: Job and CronJob created in namespace $NAMESPACE"
