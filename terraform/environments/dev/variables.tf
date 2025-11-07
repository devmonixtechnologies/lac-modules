variable "environment" {
  description = "Environment identifier"
  type        = string
  default     = "dev"
}

variable "create_log_processor_firehose" {
  description = "Provision Firehose delivery stream for dev"
  type        = bool
  default     = false
}

variable "log_processor_firehose_config" {
  description = "Configuration for dev Firehose log delivery"
  type = object({
    stream_name             = optional(string)
    s3_bucket_arn           = optional(string)
    buffer_size             = optional(number)
    buffer_interval_seconds = optional(number)
    compression_format      = optional(string)
    prefix                  = optional(string)
    error_output_prefix     = optional(string)
    kms_key_arn             = optional(string)
    role_arn                = optional(string)
    role_name               = optional(string)
    role_policy_statements  = optional(list(map(any)))
    tags                    = optional(map(string))
  })
  default = {
    stream_name   = "dev-service-logs"
    s3_bucket_arn = "arn:aws:s3:::dev-log-bucket"
  }
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "az_suffixes" {
  description = "Availability zone suffixes used to derive subnets"
  type        = list(string)
  default     = ["a", "b"]
}

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "dev-app"
}

variable "service_name" {
  description = "Service name applied to shared tags"
  type        = string
  default     = "sample"
}

variable "tags" {
  description = "Additional tags applied to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Owner       = "platform-team"
  }
}

variable "vpc_cidr_block" {
  description = "Primary VPC CIDR block"
  type        = string
  default     = "10.10.0.0/20"
}

variable "vpc_secondary_cidr_blocks" {
  description = "Optional secondary CIDR blocks"
  type        = list(string)
  default     = []
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true
}

variable "flow_log_destination_type" {
  description = "Destination for VPC flow logs"
  type        = string
  default     = "cloud-watch-logs"
}

variable "flow_log_cloudwatch_log_group_name" {
  description = "Existing CloudWatch log group name"
  type        = string
  default     = ""
}

variable "flow_log_cloudwatch_role_arn" {
  description = "IAM role ARN for flow logs"
  type        = string
  default     = ""
}

variable "flow_log_cloudwatch_retention_days" {
  description = "Retention for CloudWatch flow logs"
  type        = number
  default     = 30
}

variable "flow_log_s3_arn" {
  description = "S3 bucket ARN for flow logs"
  type        = string
  default     = ""
}

variable "flow_log_traffic_type" {
  description = "Traffic type captured"
  type        = string
  default     = "ALL"
}

variable "additional_ingress_cidr_blocks" {
  description = "Additional CIDR blocks for ingress"
  type        = list(string)
  default     = []
}

variable "additional_ingress_security_group_ids" {
  description = "Security group IDs allowed inbound"
  type        = list(string)
  default     = []
}

variable "container_image" {
  description = "Container image for ECS service"
  type        = string
  default     = "public.ecr.aws/ecs-sample-image/amazon-ecs-sample"
}

variable "container_port" {
  description = "Application container port"
  type        = number
  default     = 3000
}

variable "container_cpu" {
  description = "CPU units for task definition"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory (MB) for task definition"
  type        = number
  default     = 512
}

variable "cpu_architecture" {
  description = "CPU architecture for task definition"
  type        = string
  default     = "X86_64"
}

variable "desired_count" {
  description = "Desired task count"
  type        = number
  default     = 2
}

variable "assign_public_ip" {
  description = "Assign public IPs to tasks"
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "Retention period for application logs"
  type        = number
  default     = 14
}

variable "log_subscription_destination_arn" {
  description = "Destination ARN for log subscription"
  type        = string
  default     = ""
}

variable "log_subscription_role_arn" {
  description = "IAM role ARN for log subscription"
  type        = string
  default     = ""
}

variable "log_subscription_create_role" {
  description = "Create IAM role for log subscription"
  type        = bool
  default     = true
}

variable "log_subscription_role_name" {
  description = "Name for created log subscription role"
  type        = string
  default     = ""
}

variable "log_subscription_role_policy_statements" {
  description = "Policy statements for created log subscription role"
  type = list(object({
    effect    = optional(string, "Allow")
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "log_subscription_filter_pattern" {
  description = "Filter pattern for log subscription"
  type        = string
  default     = ""
}

variable "log_subscription_distribution" {
  description = "Distribution mode for log subscription"
  type        = string
  default     = "ByLogStream"
}

variable "create_log_processor_lambda" {
  description = "Provision log processor Lambda for dev"
  type        = bool
  default     = true
}

variable "log_processor_lambda_config" {
  description = "Configuration for dev log processor Lambda"
  type = object({
    function_name           = optional(string)
    runtime                 = optional(string)
    handler                 = optional(string)
    source_dir              = optional(string)
    package_file            = optional(string)
    create_role             = optional(bool)
    role_name               = optional(string)
    role_arn                = optional(string)
    role_policy_statements  = optional(list(object({
      effect    = optional(string, "Allow")
      actions   = list(string)
      resources = list(string)
    })))
    environment_variables   = optional(map(string))
    timeout                 = optional(number)
    memory_size             = optional(number)
    tags                    = optional(map(string))
  })
  default = {
    function_name = "dev-log-processor"
  }
}

variable "task_environment" {
  description = "Environment variables passed to container"
  type        = map(string)
  default     = {
    ENVIRONMENT = "dev"
  }
}

variable "enable_container_insights" {
  description = "Enable ECS container insights"
  type        = bool
  default     = true
}

variable "execute_command_configuration" {
  description = "Configuration for ECS Exec"
  type = object({
    kms_key_id = optional(string)
    logging    = optional(string)
    log_configuration = optional(object({
      cloud_watch_encryption_enabled = optional(bool)
      cloud_watch_log_group_name     = optional(string)
      s3_bucket_name                 = optional(string)
      s3_encryption_enabled          = optional(bool)
      s3_key_prefix                  = optional(string)
    }))
  })
  default = null
}

variable "service_connect_defaults" {
  description = "Default namespace for Service Connect"
  type = object({
    namespace = string
  })
  default = null
}

variable "capacity_providers" {
  description = "ECS capacity providers"
  type        = list(string)
  default     = []
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategies"
  type = list(object({
    capacity_provider = string
    weight            = optional(number)
    base              = optional(number)
  }))
  default = []
}

variable "launch_type" {
  description = "ECS launch type"
  type        = string
  default     = "FARGATE"
}

variable "platform_version" {
  description = "Fargate platform version"
  type        = string
  default     = "LATEST"
}

variable "scheduling_strategy" {
  description = "ECS scheduling strategy"
  type        = string
  default     = "REPLICA"
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percentage during deployment"
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Maximum healthy percentage during deployment"
  type        = number
  default     = 200
}

variable "enable_execute_command" {
  description = "Enable ECS Exec"
  type        = bool
  default     = true
}

variable "force_new_deployment" {
  description = "Force new deployment on change"
  type        = bool
  default     = false
}

variable "propagate_tags" {
  description = "Which tags are propagated"
  type        = string
  default     = "SERVICE"
}

variable "enable_ecs_managed_tags" {
  description = "Enable ECS managed tags"
  type        = bool
  default     = true
}

variable "wait_for_steady_state" {
  description = "Wait for service steady state"
  type        = bool
  default     = false
}

variable "health_check_grace_period_seconds" {
  description = "Health check grace period"
  type        = number
  default     = null
}

variable "load_balancers" {
  description = "Load balancer configurations"
  type = list(object({
    target_group_arn = string
    container_name   = string
    container_port   = number
  }))
  default = []
}

variable "service_registries" {
  description = "Service discovery registries"
  type = list(object({
    registry_arn   = string
    port           = optional(number)
    container_name = optional(string)
    container_port = optional(number)
  }))
  default = []
}

variable "deployment_circuit_breaker" {
  description = "Deployment circuit breaker configuration"
  type = object({
    enable   = bool
    rollback = bool
  })
  default = null
}

variable "deployment_controller" {
  description = "Deployment controller configuration"
  type = object({
    type = string
  })
  default = null
}

variable "capacity_provider_strategy" {
  description = "Capacity provider strategy entries"
  type = list(object({
    capacity_provider = string
    weight            = optional(number)
    base              = optional(number)
  }))
  default = []
}

variable "ordered_placement_strategy" {
  description = "Ordered placement strategies"
  type = list(object({
    type  = string
    field = optional(string)
  }))
  default = []
}
