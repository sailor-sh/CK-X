#!/bin/bash
# Setup script to create directories for all questions

# Create main exam directory
mkdir -p /tmp/exam

# Create directories for each question
for i in {1..12}; do
  mkdir -p /tmp/exam/q$i
  echo "Created directory for Question $i"
done

echo "All exam directories have been created successfully"
exit 0 