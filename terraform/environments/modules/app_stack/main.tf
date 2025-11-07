terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

module "base_tags" {
  source          = "../../../modules/shared/tags"
  environment     = var.environment
  service         = var.service_name
  component       = var.component_name
  additional_tags = var.tags
}

locals {
  name_prefix   = var.name_prefix
  cluster_name  = "${local.name_prefix}-cluster"
  service_name  = "${local.name_prefix}-service"
  task_family   = "${local.name_prefix}-task"
  log_group     = "/aws/ecs/${local.name_prefix}/application"
  base_tags     = module.base_tags.tags
  network_tags  = merge(local.base_tags, { Component = "network" })
  cluster_tags  = merge(local.base_tags, { Component = "ecs-cluster" })
  service_tags  = merge(local.base_tags, { Component = "ecs-service" })
  security_tags = merge(local.base_tags, { Component = "ecs-security" })
}

module "vpc" {
  source                     = "../../../modules/networking/vpc"
  name                       = "${local.name_prefix}-vpc"
  environment                = var.environment
  service                    = var.service_name
  component                  = "network"
  cidr_block                 = var.vpc_cidr_block
  secondary_cidr_blocks      = var.vpc_secondary_cidr_blocks
  enable_flow_logs           = var.enable_flow_logs
  flow_log_destination_type  = var.flow_log_destination_type
  flow_log_cloudwatch_log_group_name = var.flow_log_cloudwatch_log_group_name
  flow_log_cloudwatch_role_arn       = var.flow_log_cloudwatch_role_arn
  flow_log_cloudwatch_retention_days = var.flow_log_cloudwatch_retention_days
  flow_log_s3_arn            = var.flow_log_s3_arn
  flow_log_traffic_type      = var.flow_log_traffic_type
  tags                       = var.tags
  tags_override              = {}
}

module "public_subnets" {
  source      = "../../../modules/networking/subnet_set"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  service     = var.service_name
  component   = "public-subnet"
  subnet_group = "public"
  subnets     = var.public_subnets
  tags        = var.tags
  tags_override = {}
}

module "private_subnets" {
  source      = "../../../modules/networking/subnet_set"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  service     = var.service_name
  component   = "private-subnet"
  subnet_group = "private"
  subnets     = var.private_subnets
  tags        = var.tags
  tags_override = {}
}

resource "aws_security_group" "ecs_service" {
  name        = "${local.service_name}-sg"
  description = "Security group for ECS service"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow inbound traffic on application port within VPC"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = concat([module.vpc.vpc_cidr_block], var.additional_ingress_cidr_blocks)
  }

  dynamic "ingress" {
    for_each = var.additional_ingress_security_group_ids
    content {
      description              = "Security group ingress"
      from_port                = var.container_port
      to_port                  = var.container_port
      protocol                 = "tcp"
      security_groups          = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.security_tags, { Name = "${local.service_name}-sg" })
}

module "log_processor_lambda" {
  count = var.create_log_processor_lambda ? 1 : 0

  source        = "../../../modules/observability/log_processor_lambda"
  function_name = try(var.log_processor_lambda_config.function_name, "${var.environment}-${var.service_name}-log-processor")
  runtime       = try(var.log_processor_lambda_config.runtime, "python3.11")
  handler       = try(var.log_processor_lambda_config.handler, "handler.lambda_handler")
  source_dir    = try(var.log_processor_lambda_config.source_dir, "")
  package_file  = try(var.log_processor_lambda_config.package_file, "")
  create_role   = try(var.log_processor_lambda_config.create_role, true)
  role_name     = try(var.log_processor_lambda_config.role_name, "")
  role_arn      = try(var.log_processor_lambda_config.role_arn, "")
  role_policy_statements = try(var.log_processor_lambda_config.role_policy_statements, [])
  environment_variables  = try(var.log_processor_lambda_config.environment_variables, {})
  timeout                = try(var.log_processor_lambda_config.timeout, 60)
  memory_size            = try(var.log_processor_lambda_config.memory_size, 128)
  tags = merge(var.tags, { Component = "log-processor" }, try(var.log_processor_lambda_config.tags, {}))
}

module "log_processor_firehose" {
  count = var.create_log_processor_firehose ? 1 : 0

  source        = "../../../modules/observability/log_processor_firehose"
  stream_name   = try(var.log_processor_firehose_config.stream_name, "${var.environment}-${var.service_name}-logs")
  s3_bucket_arn = try(var.log_processor_firehose_config.s3_bucket_arn, "")
  buffer_size             = try(var.log_processor_firehose_config.buffer_size, 5)
  buffer_interval_seconds = try(var.log_processor_firehose_config.buffer_interval_seconds, 300)
  compression_format      = try(var.log_processor_firehose_config.compression_format, "GZIP")
  prefix                  = try(var.log_processor_firehose_config.prefix, "logs/")
  error_output_prefix     = try(var.log_processor_firehose_config.error_output_prefix, "errors/")
  kms_key_arn             = try(var.log_processor_firehose_config.kms_key_arn, "")
  role_arn                = try(var.log_processor_firehose_config.role_arn, "")
  role_name               = try(var.log_processor_firehose_config.role_name, "")
  role_policy_statements  = try(var.log_processor_firehose_config.role_policy_statements, [])
  tags = merge(var.tags, { Component = "log-processor-firehose" }, try(var.log_processor_firehose_config.tags, {}))
}

locals {
  log_processor_lambda_arn      = var.create_log_processor_lambda ? module.log_processor_lambda[0].lambda_function_arn : ""
  log_processor_lambda_role_arn = var.create_log_processor_lambda ? module.log_processor_lambda[0].lambda_role_arn : ""
  log_processor_firehose_arn      = var.create_log_processor_firehose ? module.log_processor_firehose[0].delivery_stream_arn : ""
  log_processor_firehose_role_arn = var.create_log_processor_firehose ? module.log_processor_firehose[0].role_arn : ""
  log_subscription_destination_arn_effective =
    trim(var.log_subscription_destination_arn) != "" ? var.log_subscription_destination_arn : (
      local.log_processor_lambda_arn != "" ? local.log_processor_lambda_arn : local.log_processor_firehose_arn
    )
  log_subscription_role_arn_effective =
    trim(var.log_subscription_role_arn) != "" ? var.log_subscription_role_arn : (
      local.log_subscription_destination_arn_effective == local.log_processor_lambda_arn && local.log_processor_lambda_role_arn != "" ? local.log_processor_lambda_role_arn :
      local.log_subscription_destination_arn_effective == local.log_processor_firehose_arn && local.log_processor_firehose_role_arn != "" ? local.log_processor_firehose_role_arn : ""
    )
  log_subscription_role_statements_default = (
    local.log_subscription_destination_arn_effective == local.log_processor_lambda_arn && local.log_processor_lambda_arn != "" ? [
      {
        actions   = ["lambda:InvokeFunction", "lambda:InvokeAsync"]
        resources = [local.log_processor_lambda_arn]
      }
    ] : local.log_subscription_destination_arn_effective == local.log_processor_firehose_arn && local.log_processor_firehose_arn != "" ? [
      {
        actions   = ["firehose:PutRecord", "firehose:PutRecordBatch"]
        resources = [local.log_processor_firehose_arn]
      }
    ] : []
  )
  log_subscription_role_statements_effective = length(var.log_subscription_role_policy_statements) > 0
    ? var.log_subscription_role_policy_statements
    : local.log_subscription_role_statements_default
}

module "application_log_group" {
  source      = "../../../modules/observability/logging"
  region      = var.region
  name        = local.log_group
  environment = var.environment
  service     = var.service_name
  component   = "application-logs"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_kms_key_id
  tags              = var.tags
  tags_override     = { Component = "application-logs" }
  subscription_destination_arn      = local.log_subscription_destination_arn_effective
  subscription_role_arn             = local.log_subscription_role_arn_effective
  subscription_create_role          = var.log_subscription_create_role
  subscription_role_name            = var.log_subscription_role_name
  subscription_role_policy_statements = local.log_subscription_role_statements_effective
  subscription_filter_pattern       = var.log_subscription_filter_pattern
  subscription_distribution         = var.log_subscription_distribution
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${local.name_prefix}-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags               = merge(local.service_tags, { Name = "${local.name_prefix}-exec" })
}

resource "aws_iam_role" "ecs_task" {
  name               = "${local.name_prefix}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags               = merge(local.service_tags, { Name = "${local.name_prefix}-task" })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_logs" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_ecs_task_definition" "application" {
  family                   = local.task_family
  cpu                      = tostring(var.container_cpu)
  memory                   = tostring(var.container_memory)
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  requires_compatibilities = [var.launch_type]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  container_definitions = jsonencode([
    {
      name      = "${local.name_prefix}-app"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.application_log_group.log_group_name
          awslogs-stream-prefix = "ecs"
          awslogs-region        = var.region
        }
      }
      environment = [for key, value in var.task_environment : {
        name  = key
        value = value
      }]
    }
  ])
}

module "ecs_cluster" {
  source                             = "../../../modules/compute/ecs_cluster"
  name                               = local.cluster_name
  environment                        = var.environment
  service                            = var.service_name
  component                          = "ecs-cluster"
  enable_container_insights          = var.enable_container_insights
  execute_command_configuration      = var.execute_command_configuration
  service_connect_defaults           = var.service_connect_defaults
  capacity_providers                 = var.capacity_providers
  default_capacity_provider_strategy = var.default_capacity_provider_strategy
  tags                               = var.tags
  tags_override                      = { Component = "ecs-cluster" }
}

module "ecs_service" {
  source                               = "../../../modules/compute/ecs_service"
  name                                 = local.service_name
  environment                          = var.environment
  service                              = var.service_name
  component                            = "ecs-service"
  cluster_arn                          = module.ecs_cluster.cluster_arn
  task_definition_arn                  = aws_ecs_task_definition.application.arn
  desired_count                        = var.desired_count
  launch_type                          = var.launch_type
  platform_version                     = var.platform_version
  scheduling_strategy                  = var.scheduling_strategy
  deployment_minimum_healthy_percent   = var.deployment_minimum_healthy_percent
  deployment_maximum_percent           = var.deployment_maximum_percent
  enable_execute_command               = var.enable_execute_command
  force_new_deployment                 = var.force_new_deployment
  propagate_tags                       = var.propagate_tags
  enable_ecs_managed_tags              = var.enable_ecs_managed_tags
  wait_for_steady_state                = var.wait_for_steady_state
  health_check_grace_period_seconds    = var.health_check_grace_period_seconds
  subnets                              = var.assign_public_ip ? values(module.public_subnets.subnet_ids) : values(module.private_subnets.subnet_ids)
  security_groups                      = [aws_security_group.ecs_service.id]
  assign_public_ip                     = var.assign_public_ip
  load_balancers                       = var.load_balancers
  service_registries                   = var.service_registries
  deployment_circuit_breaker           = var.deployment_circuit_breaker
  deployment_controller                = var.deployment_controller
  capacity_provider_strategy           = var.capacity_provider_strategy
  ordered_placement_strategy           = var.ordered_placement_strategy
  tags                                 = var.tags
  tags_override                        = { Component = "ecs-service" }
}

module "service_alarms" {
  source      = "../../../modules/observability/alarms"
  environment = var.environment
  service     = var.service_name
  component   = "service-alarms"
  cluster_name = module.ecs_cluster.cluster_name
  service_name = module.ecs_service.service_name
  enable_cpu_alarm    = var.alarm_enable_cpu
  cpu_threshold       = var.alarm_cpu_threshold
  cpu_evaluation_periods = var.alarm_cpu_evaluation_periods
  cpu_period          = var.alarm_cpu_period
  enable_memory_alarm = var.alarm_enable_memory
  memory_threshold    = var.alarm_memory_threshold
  memory_evaluation_periods = var.alarm_memory_evaluation_periods
  memory_period       = var.alarm_memory_period
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_ok_actions
  tags                = var.tags
  tags_override       = { Component = "service-alarms" }
}

locals {
  dashboard_template_path_resolved = var.dashboard_template_path != "" ? var.dashboard_template_path : (
    var.dashboard_template_variant == "health"
    ? "${path.module}/../../modules/observability/dashboards/templates/service_health.json"
    : "${path.module}/../../modules/observability/dashboards/templates/service_overview.json"
  )
}

module "service_dashboard" {
  count       = var.enable_dashboard ? 1 : 0
  source      = "../../../modules/observability/dashboards"
  name        = "${var.environment}-${var.service_name}-overview"
  environment = var.environment
  service     = var.service_name
  component   = "service-dashboard"
  dashboard_body = templatefile(
    local.dashboard_template_path_resolved,
    merge(var.dashboard_template_context, {
      cluster_name = module.ecs_cluster.cluster_name
      service_name = module.ecs_service.service_name
      region       = var.region
    })
  )
  tags          = var.tags
  tags_override = { Component = "service-dashboard" }
}

output "vpc_id" {
  description = "Identifier of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Map of public subnet names to IDs"
  value       = module.public_subnets.subnet_ids
}

output "private_subnet_ids" {
  description = "Map of private subnet names to IDs"
  value       = module.private_subnets.subnet_ids
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.cluster_arn
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = module.ecs_service.service_arn
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.application.arn
}
