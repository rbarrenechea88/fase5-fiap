resource "aws_sqs_queue" "donation_notifications" {
  name                       = "solidarytech-donation-notifications"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 30

  tags = {
    Project     = "SolidaryTech"
    Environment = var.environment
    CostCenter  = "NGO-Core"
    Service     = "donation-service"
  }
}

resource "aws_sqs_queue" "donation_notifications_dlq" {
  name                      = "solidarytech-donation-notifications-dlq"
  message_retention_seconds = 1209600

  tags = {
    Project     = "SolidaryTech"
    Environment = var.environment
    CostCenter  = "NGO-Core"
    Service     = "donation-service"
  }
}
