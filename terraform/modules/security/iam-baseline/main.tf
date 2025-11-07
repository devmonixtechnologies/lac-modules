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
  component       = "iam"
  additional_tags = var.tags
}

resource "aws_iam_account_password_policy" "default" {
  minimum_password_length        = var.password_policy.minimum_length
  require_lowercase_characters   = var.password_policy.require_lowercase
  require_numbers                = var.password_policy.require_numbers
  require_uppercase_characters   = var.password_policy.require_uppercase
  require_symbols                = var.password_policy.require_symbols
  allow_users_to_change_password = var.password_policy.allow_user_change
  hard_expiry                    = var.password_policy.hard_expiry
  max_password_age               = var.password_policy.max_age
  password_reuse_prevention      = var.password_policy.reuse_prevention
}

resource "aws_iam_account_alias" "this" {
  count = var.account_alias != "" ? 1 : 0
  account_alias = var.account_alias
}

resource "aws_cloudwatch_log_group" "iam_access" {
  name              = "/aws/iam/${var.environment}/access-logs"
  retention_in_days = var.access_log_retention_days
  tags              = merge(module.tags.tags, var.tags_override)
}

resource "aws_iam_role" "access_analyzer" {
  count              = var.enable_access_analyzer ? 1 : 0
  name               = "${var.name_prefix}-access-analyzer"
  assume_role_policy = data.aws_iam_policy_document.access_analyzer_assume.json

  tags = merge(
    module.tags.tags,
    var.tags_override,
    {
      Name = "${var.name_prefix}-access-analyzer"
    }
  )
}

data "aws_iam_policy_document" "access_analyzer_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["access-analyzer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_accessanalyzer_analyzer" "default" {
  count     = var.enable_access_analyzer ? 1 : 0
  analyzer_name = "${var.name_prefix}-${var.environment}-analyzer"
  type          = "ACCOUNT"
  tags          = merge(module.tags.tags, var.tags_override)
}

output "password_policy_id" {
  description = "ID of the account password policy"
  value       = aws_iam_account_password_policy.default.id
}
