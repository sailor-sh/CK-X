#!/bin/bash
# Setup environment for Question 4 - Install Nginx Chart

# No specific setup needed for this question
# The student needs to install the Bitnami nginx chart with release name web-server
# They should set the service type to NodePort and port to 30080
# The expected commands would be something like:
# helm install web-server bitnami/nginx --set service.type=NodePort --set service.nodePorts.http=30080

echo "Environment setup complete for Question 4"
exit 0 