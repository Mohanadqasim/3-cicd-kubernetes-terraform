# 🚀 CI/CD Kubernetes Deployment on AWS

This project demonstrates a complete DevOps pipeline using Terraform, Kubernetes, Docker, and GitHub Actions.

## 🏗 Infrastructure

Provisioned with **Terraform**:
- EC2 instance
- Security Group (SSH + NodePort)
- IAM role for ECR access

The EC2 instance runs:
- Docker
- Kubernetes (kubeadm)
- Flannel CNI

---

## 📦 Application

Simple Node.js (Express) app:
- Returns **"Hello World"**
- Runs on port **5000**
- Dockerized and pushed to **AWS ECR**

---

## 🔄 CI/CD Pipeline (GitHub Actions)

On push to `main`:

1. Build Docker image  
2. Push image to ECR  
3. SSH into EC2  
4. Update Kubernetes deployment  
5. Roll out new version automatically  