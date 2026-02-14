# Terraform configuration block
terraform {
  # Configure remote backend (where Terraform state is stored)
  backend "s3" {
    bucket  = "3-cicd-kubernetes-terraform" # S3 bucket name to store state file
    key     = "dev/terraform.tfstate"       # Path inside the bucket (acts like folder structure)
    region  = "eu-central-1"                # Region where the S3 bucket exists
    encrypt = true                          # Enable server-side encryption for state file
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws" # Use official AWS provider
      version = "~> 5.92"       # Allow provider versions 5.92.x
    }
  }

  required_version = ">= 1.2" # Terraform CLI must be version 1.2 or higher
}

# Configure AWS provider
provider "aws" {
  region = "eu-central-1" # All resources will be created in Frankfurt region
}

# Fetch the default VPC in the selected region
data "aws_vpc" "default" {
  default = true # Select the VPC marked as default
}

# Fetch all subnets inside the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"                  # Filter subnets by VPC ID
    values = [data.aws_vpc.default.id] # Use the default VPC ID retrieved above
  }
}

# Fetch the most recent Amazon Linux 2023 AMI for x86_64 architecture
data "aws_ami" "amazon_linux" {
  most_recent = true       # Always select the newest matching AMI
  owners      = ["amazon"] # Only official Amazon-owned AMIs

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"] # Match Amazon Linux 2023 x86_64 images
  }
}

# Create an EC2 instance to host the application
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  user_data                   = file("${path.module}/user-data.sh")
  vpc_security_group_ids      = [aws_security_group.k8s-sg.id]
  associate_public_ip_address = true

  # Attach IAM instance profile to allow EC2 instance to pull images from ECR
  iam_instance_profile = "ec2-ecr-readonly-role"

  # SSH key pair must be created in the AWS console beforehand and the name should match this value
  key_name = "devops-project-2-cicd-key"

  tags = {
    Name = "helloWorldAppServer"
  }
}

# Create a new Security Group   
resource "aws_security_group" "k8s-sg" {
  name        = "k8s"                     # Security group name in AWS console
  description = "Allow SSH and port 5000" # Description shown in console
  vpc_id      = data.aws_vpc.default.id   # Attach SG to default VPC

  # Allow SSH from anywhere
  ingress {
    description = "SSH"
    from_port   = 22            # Start of port range
    to_port     = 22            # End of port range
    protocol    = "tcp"         # TCP protocol
    cidr_blocks = ["0.0.0.0/0"] # Allow from any IPv4 address
  }

  # Allow application traffic on port 5000
  ingress {
    description = "App Port"
    from_port   = 5000 # Start of port range
    to_port     = 5000 # End of port range
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere
  }
  # Allow access to Kubernetes NodePort services
  ingress {
    description = "K8s NodePort" # Rule description shown in AWS console
    from_port   = 30000          # Start of default Kubernetes NodePort range
    to_port     = 32767          # End of default Kubernetes NodePort range
    protocol    = "tcp"          # NodePort services use TCP (most common case)
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from anywhere on the internet
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0 # All ports
    to_port     = 0
    protocol    = "-1"          # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"] # To anywhere
  }
}
# Create an ECR repository to store Docker images for the application
resource "aws_ecr_repository" "k8s" {
  name                 = "k8s"     # Repository name in ECR
  image_tag_mutability = "MUTABLE" # Allow image tags to be overwritten
  # Enable image scanning on push to catch vulnerabilities early
  image_scanning_configuration {
    scan_on_push = true
  }
}