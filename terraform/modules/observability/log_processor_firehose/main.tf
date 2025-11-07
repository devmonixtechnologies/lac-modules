terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  create_role = var.role_arn == ""
  role_arn    = local.create_role ? aws_iam_role.firehose[0].arn : var.role_arn
}

resource "aws_iam_role" "firehose" {
  count = local.create_role ? 1 : 0

  name = var.role_name != "" ? var.role_name : "${var.stream_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "firehose" {
  count = local.create_role && length(var.role_policy_statements) > 0 ? 1 : 0

  name = "${var.stream_name}-policy"
  role = aws_iam_role.firehose[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = var.role_policy_statements
  })
}

resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = var.stream_name
  destination = "extended_s3"
  tags        = var.tags

  extended_s3_configuration {
    role_arn            = local.role_arn
    bucket_arn          = var.s3_bucket_arn
    buffering_size      = var.buffer_size
    buffering_interval  = var.buffer_interval_seconds
    compression_format  = var.compression_format
    error_output_prefix = var.error_output_prefix
    prefix              = var.prefix
    kms_key_arn         = var.kms_key_arn
  }
}

output "delivery_stream_arn" {
  value       = aws_kinesis_firehose_delivery_stream.this.arn
  description = "ARN of the Firehose delivery stream"
}

output "delivery_stream_name" {
  value       = aws_kinesis_firehose_delivery_stream.this.name
  description = "Name of the Firehose delivery stream"
}

output "role_arn" {
  value       = local.role_arn
  description = "IAM role ARN used by the Firehose stream"
}
