#!/bin/bash

# Check if backup file has content and is valid
if [[ -f "/opt/etcd-backup.db" ]]; then
    # Check file size (should be greater than 0)
    SIZE=$(stat -c%s "/opt/etcd-backup.db" 2>/dev/null || stat -f%z "/opt/etcd-backup.db")
    if [[ $SIZE -gt 1000 ]]; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
