terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

module "tags" {
  source          = "../../shared/tags"
  environment     = var.environment
  service         = var.service
  component       = var.component
  additional_tags = var.tags
}

locals {
  kms_key_id                 = length(trim(var.kms_key_id)) > 0 ? var.kms_key_id : null
  subscription_destination   = trim(var.subscription_destination_arn)
  create_subscription        = length(local.subscription_destination) > 0
  subscription_role_supplied = length(trim(var.subscription_role_arn)) > 0
  create_subscription_role   = local.create_subscription && var.subscription_create_role && !local.subscription_role_supplied
}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.name
  retention_in_days = var.retention_in_days
  kms_key_id        = local.kms_key_id

  tags = merge(
    module.tags.tags,
    {
      Name = var.name
    },
    var.tags_override,
  )
}

data "aws_iam_policy_document" "subscription_assume" {
  count = local.create_subscription_role ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "subscription_inline" {
  count = local.create_subscription_role ? 1 : 0

  dynamic "statement" {
    for_each = var.subscription_role_policy_statements
    content {
      effect    = lookup(statement.value, "effect", "Allow")
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_role" "subscription" {
  count              = local.create_subscription_role ? 1 : 0
  name               = var.subscription_role_name != "" ? var.subscription_role_name : "${var.environment}-${var.service}-${var.component}-subscription"
  assume_role_policy = data.aws_iam_policy_document.subscription_assume[0].json

  tags = merge(
    module.tags.tags,
    {
      Name = var.subscription_role_name != "" ? var.subscription_role_name : "${var.environment}-${var.service}-${var.component}-subscription"
    },
    var.tags_override,
  )
}

resource "aws_iam_role_policy" "subscription" {
  count = local.create_subscription_role ? 1 : 0

  name   = "subscription-destination"
  role   = aws_iam_role.subscription[0].id
  policy = data.aws_iam_policy_document.subscription_inline[0].json
}

locals {
  subscription_role_arn = local.subscription_role_supplied ? var.subscription_role_arn : (local.create_subscription_role ? aws_iam_role.subscription[0].arn : null)
}

resource "aws_cloudwatch_log_subscription_filter" "this" {
  count = local.create_subscription ? 1 : 0

  name            = coalesce(var.subscription_filter_name, var.name)
  log_group_name  = aws_cloudwatch_log_group.this.name
  filter_pattern  = var.subscription_filter_pattern
  destination_arn = var.subscription_destination_arn
  role_arn        = local.subscription_role_arn
  distribution    = var.subscription_distribution
}

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
