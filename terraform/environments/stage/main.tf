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

locals {
  az_suffixes = var.az_suffixes

  availability_zones = [for suffix in local.az_suffixes : "${var.region}${suffix}"]

  public_subnets = [
    for idx, suffix in local.az_suffixes : {
      name                  = "${var.environment}-public-${suffix}"
      cidr_block            = cidrsubnet(var.vpc_cidr_block, 4, idx)
      az                    = local.availability_zones[idx]
      tier                  = "public"
      map_public_ip_on_launch = true
    }
  ]

  private_subnets = [
    for idx, suffix in local.az_suffixes : {
      name                  = "${var.environment}-private-${suffix}"
      cidr_block            = cidrsubnet(var.vpc_cidr_block, 4, idx + length(local.az_suffixes))
      az                    = local.availability_zones[idx]
      tier                  = "private"
      map_public_ip_on_launch = false
    }
  ]
}

module "app_stack" {
  source = "../modules/app_stack"

  environment  = var.environment
  region       = var.region
  name_prefix  = var.name_prefix
  service_name = var.service_name
  tags         = var.tags

  vpc_cidr_block            = var.vpc_cidr_block
  vpc_secondary_cidr_blocks = var.vpc_secondary_cidr_blocks

  enable_flow_logs                   = var.enable_flow_logs
  flow_log_destination_type          = var.flow_log_destination_type
  flow_log_cloudwatch_log_group_name = var.flow_log_cloudwatch_log_group_name
  flow_log_cloudwatch_role_arn       = var.flow_log_cloudwatch_role_arn
  flow_log_cloudwatch_retention_days = var.flow_log_cloudwatch_retention_days
  flow_log_s3_arn                    = var.flow_log_s3_arn
  flow_log_traffic_type              = var.flow_log_traffic_type

  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  additional_ingress_cidr_blocks        = var.additional_ingress_cidr_blocks
  additional_ingress_security_group_ids = var.additional_ingress_security_group_ids

  container_image                 = var.container_image
  container_port                  = var.container_port
  container_cpu                   = var.container_cpu
  container_memory                = var.container_memory
  cpu_architecture                = var.cpu_architecture
  desired_count                   = var.desired_count
  assign_public_ip                = var.assign_public_ip
  log_retention_in_days           = var.log_retention_in_days
  task_environment                = var.task_environment
  enable_container_insights       = var.enable_container_insights
  execute_command_configuration   = var.execute_command_configuration
  service_connect_defaults        = var.service_connect_defaults
  capacity_providers              = var.capacity_providers
  default_capacity_provider_strategy = var.default_capacity_provider_strategy
  launch_type                     = var.launch_type
  platform_version                = var.platform_version
  scheduling_strategy             = var.scheduling_strategy
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent      = var.deployment_maximum_percent
  enable_execute_command          = var.enable_execute_command
  force_new_deployment            = var.force_new_deployment
  propagate_tags                  = var.propagate_tags
  enable_ecs_managed_tags         = var.enable_ecs_managed_tags
  wait_for_steady_state           = var.wait_for_steady_state
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  load_balancers                  = var.load_balancers
  service_registries              = var.service_registries
  deployment_circuit_breaker      = var.deployment_circuit_breaker
  deployment_controller           = var.deployment_controller
  capacity_provider_strategy      = var.capacity_provider_strategy
  ordered_placement_strategy      = var.ordered_placement_strategy
  log_subscription_destination_arn      = var.log_subscription_destination_arn
  log_subscription_role_arn             = var.log_subscription_role_arn
  log_subscription_create_role          = var.log_subscription_create_role
  log_subscription_role_name            = var.log_subscription_role_name
  log_subscription_role_policy_statements = var.log_subscription_role_policy_statements
  log_subscription_filter_pattern       = var.log_subscription_filter_pattern
  log_subscription_distribution         = var.log_subscription_distribution
  create_log_processor_lambda           = var.create_log_processor_lambda
  log_processor_lambda_config           = var.log_processor_lambda_config
  create_log_processor_firehose         = var.create_log_processor_firehose
  log_processor_firehose_config         = var.log_processor_firehose_config
  enable_dashboard                      = var.enable_dashboard
  dashboard_template_path               = var.dashboard_template_path
  dashboard_template_context            = var.dashboard_template_context
}
