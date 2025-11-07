terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "processor/handler.py"
  output_path = "build/processor.zip"
}

resource "aws_iam_role" "lambda" {
  name = "${var.name}-lambda-role"

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
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "log_processor" {
  function_name = "${var.name}-log-processor"
  role          = aws_iam_role.lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.lambda_zip.output_path

  environment {
    variables = var.environment_variables
  }
}

output "lambda_function_arn" {
  value       = aws_lambda_function.log_processor.arn
  description = "ARN of the log processor Lambda"
}
