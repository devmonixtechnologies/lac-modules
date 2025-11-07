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

resource "aws_ecs_service" "this" {
  name                               = var.name
  cluster                            = var.cluster_arn
  task_definition                    = var.task_definition_arn
  desired_count                      = var.desired_count
  launch_type                        = var.launch_type
  platform_version                   = var.platform_version
  scheduling_strategy                = var.scheduling_strategy
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  enable_execute_command             = var.enable_execute_command
  force_new_deployment               = var.force_new_deployment
  propagate_tags                     = var.propagate_tags
  enable_ecs_managed_tags            = var.enable_ecs_managed_tags
  wait_for_steady_state              = var.wait_for_steady_state
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_groups
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.load_balancers
    content {
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
      target_group_arn = load_balancer.value.target_group_arn
    }
  }

  dynamic "service_registries" {
    for_each = var.service_registries
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = lookup(service_registries.value, "port", null)
      container_name = lookup(service_registries.value, "container_name", null)
      container_port = lookup(service_registries.value, "container_port", null)
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.deployment_circuit_breaker == null ? [] : [var.deployment_circuit_breaker]
    content {
      enable   = deployment_circuit_breaker.value.enable
      rollback = deployment_circuit_breaker.value.rollback
    }
  }

  dynamic "deployment_controller" {
    for_each = var.deployment_controller == null ? [] : [var.deployment_controller]
    content {
      type = deployment_controller.value.type
    }
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = lookup(capacity_provider_strategy.value, "weight", null)
      base              = lookup(capacity_provider_strategy.value, "base", null)
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = var.ordered_placement_strategy
    content {
      type  = ordered_placement_strategy.value.type
      field = lookup(ordered_placement_strategy.value, "field", null)
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

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.this.arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}
