#!/bin/bash
set -e

# This script builds the facilitator docker image with generated questions.
# It should be run from the root of the CK-X project.
echo "Building facilitator image with generated questions..."
docker build -f kubelingo/Dockerfile.facilitator -t ckx-facilitator-generated:latest .
echo "Successfully built ckx-facilitator-generated:latest"
