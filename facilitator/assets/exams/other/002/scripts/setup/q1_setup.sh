#!/bin/bash
# Setup environment for Question 1 - Verify Helm Installation

# Create necessary directories
mkdir -p /tmp/exam/q1

# Ensure Helm is installed on the system
# This is likely already set up as part of the environment initialization
# but we'll check and report status

if ! command -v helm &> /dev/null; then
  echo "❌ Helm is not installed on the system. This is a prerequisite for the helm-001 lab."
  exit 1
else
  echo "✅ Helm is installed and available for the exam."
fi

# No other setup needed for this question as it only requires checking the helm version

echo "Environment setup complete for Question 1"
exit 0 