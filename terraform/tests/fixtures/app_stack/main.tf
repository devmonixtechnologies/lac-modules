terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  s3_force_path_style         = true
}

locals {
  public_subnets = [
    {
      name                  = "test-public-a"
      cidr_block            = "10.0.0.0/24"
      az                    = "us-east-1a"
      tier                  = "public"
      map_public_ip_on_launch = true
    },
    {
      name                  = "test-public-b"
      cidr_block            = "10.0.1.0/24"
      az                    = "us-east-1b"
      tier                  = "public"
      map_public_ip_on_launch = true
    }
  ]

  private_subnets = [
    {
      name                  = "test-private-a"
      cidr_block            = "10.0.2.0/24"
      az                    = "us-east-1a"
      tier                  = "private"
      map_public_ip_on_launch = false
    },
    {
      name                  = "test-private-b"
      cidr_block            = "10.0.3.0/24"
      az                    = "us-east-1b"
      tier                  = "private"
      map_public_ip_on_launch = false
    }
  ]
}

module "app_stack" {
  source = "../../../environments/modules/app_stack"

  environment  = "test"
  region       = "us-east-1"
  name_prefix  = "fixture"
  service_name = "fixture"
  tags = {
    Environment = "test"
    Owner       = "tests"
  }

  vpc_cidr_block            = "10.0.0.0/20"
  vpc_secondary_cidr_blocks = []

  enable_flow_logs                   = false
  flow_log_destination_type          = "cloud-watch-logs"
  flow_log_cloudwatch_log_group_name = ""
  flow_log_cloudwatch_role_arn       = ""
  flow_log_cloudwatch_retention_days = 7
  flow_log_s3_arn                    = ""
  flow_log_traffic_type              = "ALL"

  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  additional_ingress_cidr_blocks        = []
  additional_ingress_security_group_ids = []

  container_image               = "nginx:latest"
  container_port                = 80
  container_cpu                 = 256
  container_memory              = 512
  cpu_architecture              = "X86_64"
  desired_count                 = 1
  assign_public_ip              = true
  log_retention_in_days         = 7
  task_environment              = {
    ENVIRONMENT = "test"
  }
  enable_container_insights     = true
  execute_command_configuration = null
  service_connect_defaults      = null
  capacity_providers            = []
  default_capacity_provider_strategy = []
  launch_type                   = "FARGATE"
  platform_version              = "LATEST"
  scheduling_strategy           = "REPLICA"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent    = 200
  enable_execute_command        = true
  force_new_deployment          = false
  propagate_tags                = "SERVICE"
  enable_ecs_managed_tags       = true
  wait_for_steady_state         = false
  health_check_grace_period_seconds = null
  load_balancers                = []
  service_registries            = []
  deployment_circuit_breaker    = null
  deployment_controller         = null
  capacity_provider_strategy    = []
  ordered_placement_strategy    = []
  enable_dashboard              = true
  log_subscription_destination_arn = "arn:aws:lambda:us-east-1:123456789012:function:log-processor"
  log_subscription_create_role     = true
  log_subscription_role_policy_statements = [
    {
      actions = ["lambda:InvokeFunction", "lambda:InvokeAsync"]
      resources = ["arn:aws:lambda:us-east-1:123456789012:function:log-processor"]
    }
  ]
  log_subscription_filter_pattern = ""
}
