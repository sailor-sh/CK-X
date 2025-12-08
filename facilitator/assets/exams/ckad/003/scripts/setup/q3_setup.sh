#!/bin/bash
set -e

# Setup for Question 3: Jobs and CronJobs
echo "Setting up environment for Jobs and CronJobs scenario..."

# Create namespace
kubectl create namespace batch-processing --dry-run=client -o yaml | kubectl apply -f -

# Create a ConfigMap with sample data for processing
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: batch-data
  namespace: batch-processing
data:
  data.csv: |
    name,age,city
    John,25,New York
    Jane,30,Los Angeles
    Bob,35,Chicago
    Alice,28,Houston
  processing-script.sh: |
    #!/bin/bash
    echo "Processing batch data..."
    wc -l /data/data.csv
    echo "Processing completed at: $(date)"
EOF

echo "Environment setup completed for Question 3 - Jobs and CronJobs"
