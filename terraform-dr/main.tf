# =============================================================
# DISASTER RECOVERY - Ohio (us-east-2)
# Este módulo NÃO é aplicado automaticamente.
# Para ativar o DR, execute: terraform init && terraform apply
# nesta pasta separada.
# =============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      Project     = "SolidaryTech"
      Environment = "DR"
      CostCenter  = "NGO-Core"
      ManagedBy   = "Terraform"
    }
  }
}

variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

module "vpc_dr" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = "solidarytech-vpc-dr"
  cidr = "10.1.0.0/16"

  azs             = ["us-east-2a", "us-east-2b"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    Project     = "SolidaryTech"
    Environment = "DR"
    CostCenter  = "NGO-Core"
  }
}

module "eks_dr" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = "solidarytech-eks-dr"
  cluster_version = "1.31"

  vpc_id     = module.vpc_dr.vpc_id
  subnet_ids = module.vpc_dr.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    dr_nodes = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }

  tags = {
    Project     = "SolidaryTech"
    Environment = "DR"
    CostCenter  = "NGO-Core"
  }
}
