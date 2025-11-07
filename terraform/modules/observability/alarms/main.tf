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
  alarm_tags = merge(
    module.tags.tags,
    var.tags_override,
    {
      Component = var.component,
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.enable_cpu_alarm ? 1 : 0
  alarm_name          = coalesce(var.cpu_alarm_name, "${var.environment}-${var.service}-${var.component}-cpu-high")
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_evaluation_periods
  threshold           = var.cpu_threshold
  period              = var.cpu_period
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_description = var.cpu_alarm_description
  alarm_actions     = var.alarm_actions
  ok_actions        = var.ok_actions

  tags = local.alarm_tags
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count               = var.enable_memory_alarm ? 1 : 0
  alarm_name          = coalesce(var.memory_alarm_name, "${var.environment}-${var.service}-${var.component}-memory-high")
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.memory_evaluation_periods
  threshold           = var.memory_threshold
  period              = var.memory_period
  statistic           = "Average"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_description = var.memory_alarm_description
  alarm_actions     = var.alarm_actions
  ok_actions        = var.ok_actions

  tags = local.alarm_tags
}

locals {
  created_alarm_arns = concat(
    [for alarm in aws_cloudwatch_metric_alarm.cpu_high : alarm.arn],
    [for alarm in aws_cloudwatch_metric_alarm.memory_high : alarm.arn],
  )

  created_alarm_names = concat(
    [for alarm in aws_cloudwatch_metric_alarm.cpu_high : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.memory_high : alarm.alarm_name],
  )
}

output "alarm_arns" {
  description = "List of CloudWatch alarm ARNs created by the module"
  value       = local.created_alarm_arns
}

output "alarm_names" {
  description = "List of CloudWatch alarm names created by the module"
  value       = local.created_alarm_names
}
