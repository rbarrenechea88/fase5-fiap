variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Production"
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
  default     = "solidarytech-eks"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "dr_region" {
  description = "DR Region for Warm Standby"
  type        = string
  default     = "us-west-2"
}
