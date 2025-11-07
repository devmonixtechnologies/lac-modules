output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.arn
}

output "subscription_filter_arn" {
  description = "ARN of the log subscription filter when created"
  value       = local.create_subscription ? aws_cloudwatch_log_subscription_filter.this[0].arn : null
}

output "subscription_role_arn" {
  description = "ARN of the IAM role used for log subscription"
  value       = local.subscription_role_arn
}
