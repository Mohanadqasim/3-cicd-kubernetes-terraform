#!/bin/bash

# Update system
dnf update -y

# Install k3s (latest stable)
curl -sfL https://get.k3s.io | sh -

# Wait for cluster to initialize
sleep 30

# Check node status
kubectl get nodes
