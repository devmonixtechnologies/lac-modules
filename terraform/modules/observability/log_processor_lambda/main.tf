terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.0"
    }
  }
}

locals {
  package_file = var.package_file != ""
    ? var.package_file
    : data.archive_file.lambda_package[0].output_path

  source_code_hash = var.package_file != ""
    ? filebase64sha256(var.package_file)
    : data.archive_file.lambda_package[0].output_base64sha256

  role_arn = var.create_role
    ? aws_iam_role.lambda[0].arn
    : var.role_arn
}

data "archive_file" "lambda_package" {
  count       = var.package_file == "" ? 1 : 0
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.cwd}/build/${var.function_name}.zip"
}

resource "aws_iam_role" "lambda" {
  count = var.create_role ? 1 : 0

  name = var.role_name != "" ? var.role_name : "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count      = var.create_role ? 1 : 0
  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_inline" {
  for_each = var.create_role ? { for idx, stmt in var.role_policy_statements : idx => stmt } : {}

  name = "${var.function_name}-inline-${each.key}"
  role = aws_iam_role.lambda[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = lookup(each.value, "effect", "Allow")
        Action   = each.value.actions
        Resource = each.value.resources
      }
    ]
  })
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = local.role_arn
  runtime       = var.runtime
  handler       = var.handler
  filename      = local.package_file
  source_code_hash = local.source_code_hash
  timeout          = var.timeout
  memory_size      = var.memory_size

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [var.environment_variables] : []
    content {
      variables = environment.value
    }
  }

  tags = var.tags
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda processor"
  value       = aws_lambda_function.this.arn
}

output "lambda_role_arn" {
  description = "ARN of the IAM role attached to the Lambda processor"
  value       = local.role_arn
}
