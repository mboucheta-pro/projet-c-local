provider "aws" {
  region = var.region
}

provider "local" {}

# Variables
locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Génération d'une paire de clés SSH
resource "tls_private_key" "deployer" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.project}-${var.environment}-key"
  public_key = tls_private_key.deployer.public_key_openssh

  lifecycle {
    ignore_changes = [public_key]
  }
}


# VPC et réseau
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Économie de coûts
  
  # Activer la résolution DNS et les noms d'hôtes DNS pour RDS
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.tags
}

# Groupe de sécurité pour les instances EC2
resource "aws_security_group" "instances" {
  name        = "${var.project}-instances-sg"
  description = "Security group for EC2 instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # À restreindre en production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# GitHub Runner
resource "aws_instance" "github_runner" {
  ami           = "ami-0a2e7efb4257c0907" # Amazon Linux 2023 pour ca-central-1
  instance_type = "t3a.small" # Bon équilibre coût/performance
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.instances.id]
  key_name      = aws_key_pair.deployer.key_name
  
  associate_public_ip_address = true // <-- Ajoute cette ligne


  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  
  tags = merge(local.tags, {
    Name = "${var.project}-github-runner"
  })

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = <<EOF
[github_runner]
${aws_instance.github_runner.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../files/id_rsa
EOF
}