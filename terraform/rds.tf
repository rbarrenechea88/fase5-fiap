resource "aws_db_subnet_group" "solidarytech" {
  name       = "solidarytech-db-subnet"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Project     = "SolidaryTech"
    Environment = var.environment
    CostCenter  = "NGO-Core"
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "solidarytech-rds-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  tags = {
    Project     = "SolidaryTech"
    Environment = var.environment
    CostCenter  = "NGO-Core"
  }
}

resource "aws_db_instance" "ngo_db" {
  identifier     = "solidarytech-ngo-db"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_encrypted     = true

  db_name  = "ngo_service"
  username = "ngo_admin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.solidarytech.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 7
  multi_az                = false
  skip_final_snapshot     = false
  final_snapshot_identifier = "solidarytech-ngo-final"

  tags = {
    Project     = "SolidaryTech"
    Environment = var.environment
    CostCenter  = "NGO-Core"
    Service     = "ngo-service"
  }
}

resource "aws_db_instance" "donation_db" {
  identifier     = "solidarytech-donation-db"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  db_name  = "donation_service"
  username = "donation_admin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.solidarytech.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 7
  multi_az                = true
  skip_final_snapshot     = false
  final_snapshot_identifier = "solidarytech-donation-final"

  tags = {
    Project     = "SolidaryTech"
    Environment = var.environment
    CostCenter  = "NGO-Core"
    Service     = "donation-service"
  }
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}
