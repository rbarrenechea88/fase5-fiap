output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "rds_ngo_endpoint" {
  value = aws_db_instance.ngo_db.endpoint
}

output "rds_donation_endpoint" {
  value = aws_db_instance.donation_db.endpoint
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.volunteers.name
}

output "sqs_queue_url" {
  value = aws_sqs_queue.donation_notifications.url
}
