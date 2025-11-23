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
  component       = "cost-optimization"
  additional_tags = var.tags
}

resource "aws_ce_anomaly_monitor" "this" {
  count = var.enable_cost_anomaly_detection ? 1 : 0

  name        = "${var.environment}-${var.service}-cost-anomaly-monitor"
  monitor_type = "DIMENSIONAL"

  monitor_dimension {
    name  = "SERVICE"
    match = var.monitored_services
  }

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_ce_anomaly_subscription" "this" {
  count = var.enable_cost_anomaly_detection ? 1 : 0

  name      = "${var.environment}-${var.service}-cost-anomaly-subscription"
  frequency = var.anomaly_detection_frequency

  subscriber {
    type    = "EMAIL"
    address = var.anomaly_notification_email
  }

  subscriber {
    type    = "SNS"
    address = var.anomaly_sns_topic_arn
  }

  threshold_expression {
    dimension {
      name  = "ANOMALY_DETECTION_SEVERITY"
      match = var.anomaly_severity_levels
    }
  }

  monitor_arn_list = [aws_ce_anomaly_monitor.this[0].arn]

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_ce_cost_allocation_tag" "this" {
  for_each = var.cost_allocation_tags

  tag_key = each.key
  status  = each.value.active ? "Active" : "Inactive"
}

resource "aws_budgets_budget" "this" {
  for_each = var.budgets

  name              = "${var.environment}-${var.service}-${each.key}"
  budget_type       = each.value.budget_type
  time_unit         = each.value.time_unit
  time_period_start = each.value.time_period_start

  dynamic "limit_amount" {
    for_each = each.value.budget_type == "COST" || each.value.budget_type == "USAGE" ? [each.value.limit_amount] : []
    content {
      amount = limit_amount.value.amount
      unit   = lookup(limit_amount.value, "unit", "USD")
    }
  }

  dynamic "limit_amount" {
    for_each = each.value.budget_type == "RI_UTILIZATION" || each.value.budget_type == "SAVINGS_PLANS_UTILIZATION" ? [each.value.limit_amount] : []
    content {
      amount = limit_amount.value.amount
      unit   = "PERCENTAGE"
    }
  }

  dynamic "cost_filter" {
    for_each = each.value.cost_filters
    content {
      name   = cost_filter.value.name
      values = cost_filter.value.values
    }
  }

  dynamic "cost_types" {
    for_each = each.value.cost_types != null ? [each.value.cost_types] : []
    content {
      include_credit             = lookup(cost_types.value, "include_credit", true)
      include_discount          = lookup(cost_types.value, "include_discount", true)
      include_other_subscription = lookup(cost_types.value, "include_other_subscription", true)
      include_recurring         = lookup(cost_types.value, "include_recurring", true)
      include_refund             = lookup(cost_types.value, "include_refund", true)
      include_subscription      = lookup(cost_types.value, "include_subscription", true)
      include_support           = lookup(cost_types.value, "include_support", true)
      include_tax               = lookup(cost_types.value, "include_tax", true)
      include_upfront           = lookup(cost_types.value, "include_upfront", true)
      use_amortized             = lookup(cost_types.value, "use_amortized", false)
      use_blended              = lookup(cost_types.value, "use_blended", false)
    }
  }

  dynamic "notification" {
    for_each = each.value.notifications
    content {
      comparison_operator        = notification.value.comparison_operator
      threshold                  = notification.value.threshold
      threshold_type             = notification.value.threshold_type
      notification_type          = notification.value.notification_type
      subscriber_email_addresses = notification.value.subscriber_email_addresses
      subscriber_sns_topic_arns  = notification.value.subscriber_sns_topic_arns
    }
  }

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_sns_topic" "cost_alerts" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.environment}-${var.service}-cost-alerts"

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_sns_topic_policy" "cost_alerts" {
  count = var.create_sns_topic ? 1 : 0
  arn   = aws_sns_topic.cost_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSBudgetsAccess"
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.cost_alerts[0].arn
      }
    ]
  })
}

resource "aws_iam_role" "cost_optimizer" {
  count = var.enable_automated_optimization ? 1 : 0
  name  = "${var.environment}-${var.service}-cost-optimizer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_iam_role_policy_attachment" "cost_optimizer_basic" {
  count      = var.enable_automated_optimization ? 1 : 0
  role       = aws_iam_role.cost_optimizer[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "cost_optimizer" {
  count = var.enable_automated_optimization ? 1 : 0
  role  = aws_iam_role.cost_optimizer[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:ListServices"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:SetDesiredCapacity"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetDimensionValues"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "cost_optimizer" {
  count = var.enable_automated_optimization ? 1 : 0

  filename         = "cost_optimizer.zip"
  function_name    = "${var.environment}-${var.service}-cost-optimizer"
  role            = aws_iam_role.cost_optimizer[0].arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  source_code_hash = data.archive_file.cost_optimizer[0].output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL  = var.optimization_log_level
    }
  }

  tags = merge(module.tags.tags, var.tags_override)

  depends_on = [aws_iam_role_policy_attachment.cost_optimizer_basic]
}

data "archive_file" "cost_optimizer" {
  count = var.enable_automated_optimization ? 1 : 0
  type  = "zip"

  source_content = <<-EOF
import json
import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

def handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Cost optimization logic here
    # This is a placeholder for actual optimization logic
    
    return {
        'statusCode': 200,
        'body': json.dumps('Cost optimization completed')
    }
EOF

  output_path = "${path.module}/cost_optimizer.zip"
}

resource "aws_cloudwatch_event_rule" "cost_optimizer_schedule" {
  count = var.enable_automated_optimization ? 1 : 0
  name  = "${var.environment}-${var.service}-cost-optimizer-schedule"

  schedule_expression = var.optimization_schedule

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_cloudwatch_event_target" "cost_optimizer" {
  count = var.enable_automated_optimization ? 1 : 0
  rule  = aws_cloudwatch_event_rule.cost_optimizer_schedule[0].name
  arn   = aws_lambda_function.cost_optimizer[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count = var.enable_automated_optimization ? 1 : 0

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_optimizer[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_optimizer_schedule[0].arn
}

resource "aws_ec2_spot_datafeed_subscription" "this" {
  count = var.enable_spot_datafeed ? 1 : 0
  bucket = var.spot_datafeed_bucket
  prefix = var.spot_datafeed_prefix

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_ce_cost_category" "this" {
  count = var.enable_cost_categories ? 1 : 0

  name     = "${var.environment}-${var.service}-cost-category"
  rule_version = "COST_CATEGORY_API_VERSION_1"

  rule {
    dynamic "rule" {
      for_each = var.cost_category_rules
      content {
        value = rule.value.value
        
        dynamic "inherited_value" {
          for_each = rule.value.inherited_value != null ? [rule.value.inherited_value] : []
          content {
            dimension_name = inherited_value.value.dimension_name
            dimension_key  = inherited_value.value.dimension_key
          }
        }

        dynamic "type" {
          for_each = rule.value.type != null ? [rule.value.type] : []
          content {
            dimension = type.value.dimension
            key       = type.value.key
            match_options = type.value.match_options
            values       = type.value.values
          }
        }
      }
    }
  }

  tags = merge(module.tags.tags, var.tags_override)
}

output "cost_anomaly_monitor_arn" {
  description = "ARN of the cost anomaly monitor"
  value       = var.enable_cost_anomaly_detection ? aws_ce_anomaly_monitor.this[0].arn : null
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for cost alerts"
  value       = var.create_sns_topic ? aws_sns_topic.cost_alerts[0].arn : null
}

output "cost_optimizer_lambda_arn" {
  description = "ARN of the cost optimizer Lambda function"
  value       = var.enable_automated_optimization ? aws_lambda_function.cost_optimizer[0].arn : null
}
