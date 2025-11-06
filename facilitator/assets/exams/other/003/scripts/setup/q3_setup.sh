#!/bin/bash

# Setup for Question 2: Create a Pod with liveness and readiness probes

# Create the workloads namespace if it doesn't exist already
if ! kubectl get namespace workloads &> /dev/null; then
    kubectl create namespace workloads
fi

# Delete any existing Pod with the same name
kubectl delete pod health-pod -n workloads --ignore-not-found=true

# Create an index.html and healthz endpoint for testing the probes
cat <<EOF > /tmp/index.html
<!DOCTYPE html>
<html>
<head>
    <title>CKAD Exam</title>
</head>
<body>
    <h1>Welcome to the CKAD Practice Exam!</h1>
</body>
</html>
EOF

cat <<EOF > /tmp/healthz
OK
EOF

echo "Setup complete for Question 2: Environment ready for creating Pod 'health-pod' with liveness and readiness probes"
echo "Note: In a real environment, you would need to set up files at /healthz in the container."
exit 0 