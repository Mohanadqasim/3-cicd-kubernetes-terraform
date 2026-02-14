#!/bin/bash
set -eux

# Update system
yum update -y

# Install Docker
yum install -y docker

# Start Docker and enable on boot
systemctl start docker
systemctl enable docker

# Allow ec2-user to run docker without sudo
usermod -aG docker ec2-user

# Log completion
echo "Docker installed successfully" > /var/log/user-data.log