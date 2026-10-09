#!/bin/bash

# Check if backup file exists
if [[ -f "/opt/etcd-backup.db" ]]; then
    exit 0
else
    exit 1
fi
