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
  container_insights_setting = var.enable_container_insights ? "enabled" : "disabled"
}

resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = local.container_insights_setting
  }

  dynamic "configuration" {
    for_each = var.execute_command_configuration == null ? [] : [var.execute_command_configuration]
    content {
      execute_command_configuration {
        kms_key_id = lookup(configuration.value, "kms_key_id", null)
        logging     = lookup(configuration.value, "logging", null)

        dynamic "log_configuration" {
          for_each = try([configuration.value.log_configuration], [])
          content {
            cloud_watch_encryption_enabled = lookup(log_configuration.value, "cloud_watch_encryption_enabled", null)
            cloud_watch_log_group_name     = lookup(log_configuration.value, "cloud_watch_log_group_name", null)
            s3_bucket_name                 = lookup(log_configuration.value, "s3_bucket_name", null)
            s3_encryption_enabled          = lookup(log_configuration.value, "s3_encryption_enabled", null)
            s3_key_prefix                  = lookup(log_configuration.value, "s3_key_prefix", null)
          }
        }
      }
    }
  }

  dynamic "service_connect_defaults" {
    for_each = var.service_connect_defaults == null ? [] : [var.service_connect_defaults]
    content {
      namespace = service_connect_defaults.value.namespace
    }
  }

  tags = merge(
    module.tags.tags,
    {
      Name = var.name
    },
    var.tags_override,
  )
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count = length(var.capacity_providers) > 0 ? 1 : 0

  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    content {
      base              = lookup(default_capacity_provider_strategy.value, "base", null)
      weight            = lookup(default_capacity_provider_strategy.value, "weight", null)
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
    }
  }
}

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}
