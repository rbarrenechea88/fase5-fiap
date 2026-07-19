# S3 bucket para backups do Velero
resource "aws_s3_bucket" "velero_backups" {
  bucket = "solidarytech-velero-backups"

  tags = {
    Project     = "SolidaryTech"
    Environment = var.environment
    CostCenter  = "NGO-Core"
    Purpose     = "Disaster-Recovery"
  }
}

resource "aws_s3_bucket_versioning" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    expiration {
      days = 30
    }

    transition {
      days          = 7
      storage_class = "STANDARD_IA"
    }
  }
}

# IAM Role para Velero (IRSA)
resource "aws_iam_role" "velero" {
  name = "solidarytech-velero-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:velero:velero-server"
          }
        }
      }
    ]
  })

  tags = {
    Project     = "SolidaryTech"
    Environment = var.environment
    CostCenter  = "NGO-Core"
  }
}

resource "aws_iam_role_policy" "velero" {
  name = "solidarytech-velero-policy"
  role = aws_iam_role.velero.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "${aws_s3_bucket.velero_backups.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.velero_backups.arn
      }
    ]
  })
}
